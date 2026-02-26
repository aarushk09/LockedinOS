const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  // Tasks
  tasks: {
    getAll: () => ipcRenderer.invoke('tasks:getAll'),
    create: (task) => ipcRenderer.invoke('tasks:create', task),
    update: (task) => ipcRenderer.invoke('tasks:update', task),
    delete: (id) => ipcRenderer.invoke('tasks:delete', id),
  },
  // Notes
  notes: {
    getAll: () => ipcRenderer.invoke('notes:getAll'),
    create: (note) => ipcRenderer.invoke('notes:create', note),
    update: (note) => ipcRenderer.invoke('notes:update', note),
    delete: (id) => ipcRenderer.invoke('notes:delete', id),
  },
  // Focus Mode
  focus: {
    getStatus: () => ipcRenderer.invoke('focus:getStatus'),
    toggle: () => ipcRenderer.invoke('focus:toggle'),
  },
  // System
  system: {
    launchApp: (command) => ipcRenderer.invoke('system:launchApp', command),
    openExternal: (url) => ipcRenderer.invoke('system:openExternal', url),
  },
  // Window controls
  window: {
    minimize: () => ipcRenderer.invoke('window:minimize'),
    maximize: () => ipcRenderer.invoke('window:maximize'),
    close: () => ipcRenderer.invoke('window:close'),
  },
});
