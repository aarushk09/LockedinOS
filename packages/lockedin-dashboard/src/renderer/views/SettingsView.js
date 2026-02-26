import React, { useState, useEffect } from 'react';

export default function SettingsView() {
  const [focusActive, setFocusActive] = useState(false);

  useEffect(() => {
    window.electronAPI.focus.getStatus().then(s => setFocusActive(s.active)).catch(() => {});
  }, []);

  const handleFocusToggle = async () => {
    const result = await window.electronAPI.focus.toggle();
    setFocusActive(result.active);
  };

  return (
    <div className="settings-view">
      <h2>Settings</h2>

      <div className="settings-section">
        <h3>Focus Mode</h3>
        <div className="setting-row">
          <div className="setting-info">
            <strong>Focus Mode</strong>
            <p>Blocks distracting websites and enables Do Not Disturb.</p>
          </div>
          <button className={`toggle-switch ${focusActive ? 'on' : ''}`} onClick={handleFocusToggle}>
            <span className="toggle-knob" />
          </button>
        </div>
        <div className="setting-row">
          <div className="setting-info">
            <strong>Blocked Websites</strong>
            <p>Edit the blocklist at /etc/lockedin/focus-blocklist.txt</p>
          </div>
          <button className="btn btn-ghost btn-sm" onClick={() => window.electronAPI.system.launchApp('gnome-text-editor /etc/lockedin/focus-blocklist.txt')}>
            Edit
          </button>
        </div>
      </div>

      <div className="settings-section">
        <h3>Appearance</h3>
        <div className="setting-row">
          <div className="setting-info">
            <strong>System Settings</strong>
            <p>Open GNOME system settings for display, sound, and more.</p>
          </div>
          <button className="btn btn-ghost btn-sm" onClick={() => window.electronAPI.system.launchApp('gnome-control-center')}>
            Open
          </button>
        </div>
      </div>

      <div className="settings-section">
        <h3>About</h3>
        <div className="about-card">
          <h4>🛡 LockedinOS v1.0.0</h4>
          <p>A distraction-free Linux environment built for students.</p>
          <p className="about-muted">Built with Electron, React, GNOME, and Ubuntu.</p>
        </div>
      </div>
    </div>
  );
}
