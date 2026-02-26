import React from 'react';

export default function FilesView() {
  const openFiles = () => window.electronAPI.system.launchApp('nautilus');

  return (
    <div className="files-view">
      <div className="files-header">
        <h2>Files</h2>
        <button className="btn btn-primary" onClick={openFiles}>Open File Manager</button>
      </div>
      <div className="files-grid">
        <FileCard icon="📁" name="Home" onClick={() => window.electronAPI.system.launchApp('nautilus ~')} />
        <FileCard icon="📄" name="Documents" onClick={() => window.electronAPI.system.launchApp('nautilus ~/Documents')} />
        <FileCard icon="🖼" name="Pictures" onClick={() => window.electronAPI.system.launchApp('nautilus ~/Pictures')} />
        <FileCard icon="🎵" name="Music" onClick={() => window.electronAPI.system.launchApp('nautilus ~/Music')} />
        <FileCard icon="🎬" name="Videos" onClick={() => window.electronAPI.system.launchApp('nautilus ~/Videos')} />
        <FileCard icon="⬇️" name="Downloads" onClick={() => window.electronAPI.system.launchApp('nautilus ~/Downloads')} />
        <FileCard icon="🗑" name="Trash" onClick={() => window.electronAPI.system.launchApp('nautilus trash:///')} />
      </div>
    </div>
  );
}

function FileCard({ icon, name, onClick }) {
  return (
    <button className="file-card" onClick={onClick}>
      <span className="file-icon">{icon}</span>
      <span className="file-name">{name}</span>
    </button>
  );
}
