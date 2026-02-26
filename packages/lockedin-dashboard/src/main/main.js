const { app, BrowserWindow, ipcMain, shell } = require('electron');
const path = require('path');
const { execSync, exec } = require('child_process');
const { initDatabase, getDb } = require('./database');

let mainWindow = null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 900,
    minHeight: 600,
    title: 'LockedinOS Dashboard',
    icon: path.join(__dirname, '..', '..', 'assets', 'icon.png'),
    frame: false,
    transparent: false,
    backgroundColor: '#0f1923',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadFile(path.join(__dirname, '..', 'renderer', 'index.html'));
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '..', '..', 'dist', 'index.html'));
  }

  mainWindow.maximize();

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  initDatabase();
  createWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});

// ── Task IPC Handlers ──

ipcMain.handle('tasks:getAll', () => {
  const db = getDb();
  return db.prepare('SELECT * FROM tasks ORDER BY completed ASC, due_date ASC, created_at DESC').all();
});

ipcMain.handle('tasks:create', (_event, task) => {
  const db = getDb();
  const { id, title, description, due_date, priority, tags, completed } = task;
  db.prepare(`
    INSERT INTO tasks (id, title, description, due_date, priority, tags, completed)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(id, title, description || '', due_date || null, priority || 'medium', tags || '', completed ? 1 : 0);
  return db.prepare('SELECT * FROM tasks WHERE id = ?').get(id);
});

ipcMain.handle('tasks:update', (_event, task) => {
  const db = getDb();
  const { id, title, description, due_date, priority, tags, completed } = task;
  db.prepare(`
    UPDATE tasks SET title = ?, description = ?, due_date = ?, priority = ?, tags = ?, completed = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `).run(title, description || '', due_date || null, priority || 'medium', tags || '', completed ? 1 : 0, id);
  return db.prepare('SELECT * FROM tasks WHERE id = ?').get(id);
});

ipcMain.handle('tasks:delete', (_event, id) => {
  const db = getDb();
  db.prepare('DELETE FROM tasks WHERE id = ?').run(id);
  return { success: true };
});

// ── Notes IPC Handlers ──

ipcMain.handle('notes:getAll', () => {
  const db = getDb();
  return db.prepare('SELECT * FROM notes ORDER BY updated_at DESC').all();
});

ipcMain.handle('notes:create', (_event, note) => {
  const db = getDb();
  const { id, title, content } = note;
  db.prepare('INSERT INTO notes (id, title, content) VALUES (?, ?, ?)').run(id, title || 'Untitled', content || '');
  return db.prepare('SELECT * FROM notes WHERE id = ?').get(id);
});

ipcMain.handle('notes:update', (_event, note) => {
  const db = getDb();
  const { id, title, content } = note;
  db.prepare('UPDATE notes SET title = ?, content = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(title, content, id);
  return db.prepare('SELECT * FROM notes WHERE id = ?').get(id);
});

ipcMain.handle('notes:delete', (_event, id) => {
  const db = getDb();
  db.prepare('DELETE FROM notes WHERE id = ?').run(id);
  return { success: true };
});

// ── Focus Mode IPC ──

ipcMain.handle('focus:getStatus', () => {
  try {
    const output = execSync('lockedin-focus status 2>/dev/null', { encoding: 'utf8', timeout: 3000 });
    return { active: output.includes('ACTIVE'), raw: output.trim() };
  } catch {
    return { active: false, raw: 'Focus mode unavailable' };
  }
});

ipcMain.handle('focus:toggle', () => {
  try {
    execSync('lockedin-focus toggle 2>/dev/null', { timeout: 5000 });
    const output = execSync('lockedin-focus status 2>/dev/null', { encoding: 'utf8', timeout: 3000 });
    return { active: output.includes('ACTIVE') };
  } catch {
    return { active: false };
  }
});

// ── System IPC ──

ipcMain.handle('system:launchApp', (_event, command) => {
  exec(command, { detached: true, stdio: 'ignore' });
  return { success: true };
});

ipcMain.handle('system:openExternal', (_event, url) => {
  shell.openExternal(url);
  return { success: true };
});

// ── Window controls ──

ipcMain.handle('window:minimize', () => mainWindow?.minimize());
ipcMain.handle('window:maximize', () => {
  if (mainWindow?.isMaximized()) mainWindow.unmaximize();
  else mainWindow?.maximize();
});
ipcMain.handle('window:close', () => mainWindow?.close());
