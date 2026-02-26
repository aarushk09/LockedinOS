import React, { useState } from 'react';
import TopBar from './components/TopBar';
import Sidebar from './components/Sidebar';
import BottomTabBar from './components/BottomTabBar';
import DashboardView from './views/DashboardView';
import NotesView from './views/NotesView';
import FilesView from './views/FilesView';
import SettingsView from './views/SettingsView';

const TABS = { DASHBOARD: 'dashboard', FILES: 'files', NOTES: 'notes', SETTINGS: 'settings' };

export default function App() {
  const [activeTab, setActiveTab] = useState(TABS.DASHBOARD);

  const renderView = () => {
    switch (activeTab) {
      case TABS.DASHBOARD: return <DashboardView />;
      case TABS.FILES: return <FilesView />;
      case TABS.NOTES: return <NotesView />;
      case TABS.SETTINGS: return <SettingsView />;
      default: return <DashboardView />;
    }
  };

  return (
    <div className="shell">
      <TopBar />
      <div className="shell-body">
        <Sidebar />
        <main className="shell-content">
          {renderView()}
        </main>
      </div>
      <BottomTabBar activeTab={activeTab} onTabChange={setActiveTab} />
    </div>
  );
}
