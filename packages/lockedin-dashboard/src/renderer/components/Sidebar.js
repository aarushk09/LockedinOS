import React from 'react';

const APPS = [
  { name: 'Files', icon: '📁', command: 'nautilus' },
  { name: 'LockedIn Web', icon: '🌐', command: 'chromium-browser || google-chrome || firefox' },
  { name: 'Code Editor', icon: '💻', command: 'gnome-text-editor || gedit' },
  { name: 'Media Player', icon: '🎵', command: 'totem || vlc' },
  { name: 'Flatpak Hub', icon: '🏪', command: 'gnome-software' },
];

export default function Sidebar() {
  const launchApp = (command) => {
    window.electronAPI.system.launchApp(command);
  };

  return (
    <aside className="sidebar">
      <div className="sidebar-apps">
        {APPS.map((app) => (
          <button
            key={app.name}
            className="sidebar-app-btn"
            onClick={() => launchApp(app.command)}
            title={app.name}
          >
            <span className="sidebar-app-icon">{app.icon}</span>
            <span className="sidebar-app-name">{app.name}</span>
          </button>
        ))}
      </div>
      <button
        className="sidebar-app-btn sidebar-all-apps"
        onClick={() => launchApp('gnome-shell --overview')}
        title="All Apps"
      >
        <span className="sidebar-app-icon">＋</span>
        <span className="sidebar-app-name">All Apps</span>
      </button>
    </aside>
  );
}
