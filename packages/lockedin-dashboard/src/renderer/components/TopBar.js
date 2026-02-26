import React, { useState, useEffect } from 'react';

export default function TopBar() {
  const [time, setTime] = useState(new Date());
  const [focusActive, setFocusActive] = useState(false);

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    window.electronAPI.focus.getStatus().then(s => setFocusActive(s.active)).catch(() => {});
    return () => clearInterval(timer);
  }, []);

  const handleFocusToggle = async () => {
    const result = await window.electronAPI.focus.toggle();
    setFocusActive(result.active);
  };

  const formatDate = (d) => {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${days[d.getDay()]}, ${months[d.getMonth()]} ${d.getDate()}`;
  };

  const formatTime = (d) => {
    return d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
  };

  return (
    <header className="topbar" onDoubleClick={() => window.electronAPI.window.maximize()}>
      <div className="topbar-left">
        <div className="topbar-brand">
          <span className="brand-icon">🛡</span>
          <span className="brand-name">LockedinOS</span>
          <span className="brand-version">v1</span>
        </div>
      </div>
      <div className="topbar-center">
        <span className="focus-label">Focus Mode:</span>
        <span className={`focus-status ${focusActive ? 'on' : 'off'}`}>
          {focusActive ? 'ON' : 'OFF'}
        </span>
        <button className="focus-toggle-btn" onClick={handleFocusToggle}>
          {focusActive ? 'Disable' : 'Enable'}
        </button>
      </div>
      <div className="topbar-right">
        <span className="topbar-datetime">{formatDate(time)}  {formatTime(time)}</span>
        <div className="topbar-icons">
          <button className="topbar-icon-btn" title="Wi-Fi">📶</button>
          <button className="topbar-icon-btn" title="Notifications">🔔</button>
          <button className="topbar-icon-btn" title="Settings" onClick={() => window.electronAPI.system.launchApp('gnome-control-center')}>⚙️</button>
        </div>
        <div className="window-controls">
          <button className="win-btn win-minimize" onClick={() => window.electronAPI.window.minimize()}>─</button>
          <button className="win-btn win-maximize" onClick={() => window.electronAPI.window.maximize()}>□</button>
          <button className="win-btn win-close" onClick={() => window.electronAPI.window.close()}>✕</button>
        </div>
      </div>
    </header>
  );
}
