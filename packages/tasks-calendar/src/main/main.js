const { app, BrowserWindow, ipcMain, globalShortcut } = require('electron');
const path = require('path');
const { initDatabase, getDb } = require('./database');

let mainWindow = null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 768,
    minWidth: 600,
    minHeight: 500,
    title: 'LockedIn Tasks & Calendar',
    icon: path.join(__dirname, '..', '..', 'assets', 'icon.png'),
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

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  initDatabase();
  createWindow();

  globalShortcut.register('CommandOrControl+N', () => {
    if (mainWindow) {
      mainWindow.webContents.send('shortcut:new-task');
    }
  });

  globalShortcut.register('CommandOrControl+S', () => {
    if (mainWindow) {
      mainWindow.webContents.send('shortcut:save');
    }
  });
});

app.on('window-all-closed', () => {
  globalShortcut.unregisterAll();
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});

// ── IPC Handlers ──

ipcMain.handle('tasks:getAll', () => {
  const db = getDb();
  return db.prepare('SELECT * FROM tasks ORDER BY created_at DESC').all();
});

ipcMain.handle('tasks:getById', (_event, id) => {
  const db = getDb();
  return db.prepare('SELECT * FROM tasks WHERE id = ?').get(id);
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

ipcMain.handle('tasks:getByDateRange', (_event, startDate, endDate) => {
  const db = getDb();
  return db.prepare('SELECT * FROM tasks WHERE due_date >= ? AND due_date <= ? ORDER BY due_date ASC').all(startDate, endDate);
});
