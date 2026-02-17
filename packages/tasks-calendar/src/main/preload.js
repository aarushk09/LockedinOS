const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  tasks: {
    getAll: () => ipcRenderer.invoke('tasks:getAll'),
    getById: (id) => ipcRenderer.invoke('tasks:getById', id),
    create: (task) => ipcRenderer.invoke('tasks:create', task),
    update: (task) => ipcRenderer.invoke('tasks:update', task),
    delete: (id) => ipcRenderer.invoke('tasks:delete', id),
    getByDateRange: (start, end) => ipcRenderer.invoke('tasks:getByDateRange', start, end),
  },
  onNewTask: (callback) => ipcRenderer.on('shortcut:new-task', callback),
  onSave: (callback) => ipcRenderer.on('shortcut:save', callback),
  removeListener: (channel, callback) => ipcRenderer.removeListener(channel, callback),
});
