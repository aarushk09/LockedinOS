import React from 'react';

const TABS = [
  { id: 'dashboard', label: 'Dashboard', icon: '🛡' },
  { id: 'files', label: 'Files', icon: '📁' },
  { id: 'notes', label: 'Notes', icon: '📝' },
  { id: 'settings', label: 'Settings', icon: '⚙️' },
];

export default function BottomTabBar({ activeTab, onTabChange }) {
  return (
    <nav className="bottom-tab-bar">
      {TABS.map((tab) => (
        <button
          key={tab.id}
          className={`bottom-tab ${activeTab === tab.id ? 'active' : ''}`}
          onClick={() => onTabChange(tab.id)}
        >
          <span className="bottom-tab-icon">{tab.icon}</span>
          <span className="bottom-tab-label">{tab.label}</span>
        </button>
      ))}
    </nav>
  );
}
