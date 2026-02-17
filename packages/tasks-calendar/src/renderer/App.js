import React, { useState, useEffect, useCallback } from 'react';
import TaskList from './components/TaskList';
import TaskEditor from './components/TaskEditor';
import CalendarView from './components/CalendarView';
import './styles/app.css';

const TABS = { TASKS: 'tasks', CALENDAR: 'calendar' };

export default function App() {
  const [activeTab, setActiveTab] = useState(TABS.TASKS);
  const [tasks, setTasks] = useState([]);
  const [editingTask, setEditingTask] = useState(null);
  const [showEditor, setShowEditor] = useState(false);

  const loadTasks = useCallback(async () => {
    const allTasks = await window.electronAPI.tasks.getAll();
    setTasks(allTasks);
  }, []);

  useEffect(() => {
    loadTasks();
  }, [loadTasks]);

  useEffect(() => {
    const handleNewTask = () => {
      setEditingTask(null);
      setShowEditor(true);
      setActiveTab(TABS.TASKS);
    };
    window.electronAPI.onNewTask(handleNewTask);
    return () => window.electronAPI.removeListener('shortcut:new-task', handleNewTask);
  }, []);

  const handleCreateTask = async (task) => {
    await window.electronAPI.tasks.create(task);
    await loadTasks();
    setShowEditor(false);
    setEditingTask(null);
  };

  const handleUpdateTask = async (task) => {
    await window.electronAPI.tasks.update(task);
    await loadTasks();
    setShowEditor(false);
    setEditingTask(null);
  };

  const handleDeleteTask = async (id) => {
    await window.electronAPI.tasks.delete(id);
    await loadTasks();
    setShowEditor(false);
    setEditingTask(null);
  };

  const handleEditTask = (task) => {
    setEditingTask(task);
    setShowEditor(true);
  };

  const handleToggleComplete = async (task) => {
    await window.electronAPI.tasks.update({ ...task, completed: task.completed ? 0 : 1 });
    await loadTasks();
  };

  const handleNewTask = () => {
    setEditingTask(null);
    setShowEditor(true);
  };

  const handleCalendarDateClick = (date) => {
    setEditingTask(null);
    setShowEditor(true);
    setEditingTask({ due_date: date });
  };

  return (
    <div className="app">
      <header className="app-header">
        <div className="app-logo">
          <span className="logo-icon">&#9889;</span>
          <h1>LockedIn</h1>
        </div>
        <nav className="tab-nav">
          <button
            className={`tab-btn ${activeTab === TABS.TASKS ? 'active' : ''}`}
            onClick={() => setActiveTab(TABS.TASKS)}
          >
            Tasks
          </button>
          <button
            className={`tab-btn ${activeTab === TABS.CALENDAR ? 'active' : ''}`}
            onClick={() => setActiveTab(TABS.CALENDAR)}
          >
            Calendar
          </button>
        </nav>
      </header>

      <main className="app-content">
        {activeTab === TABS.TASKS && (
          <div className="tasks-view">
            <TaskList
              tasks={tasks}
              onEdit={handleEditTask}
              onToggleComplete={handleToggleComplete}
              onNewTask={handleNewTask}
            />
            {showEditor && (
              <TaskEditor
                task={editingTask}
                onSave={editingTask?.id ? handleUpdateTask : handleCreateTask}
                onDelete={editingTask?.id ? handleDeleteTask : null}
                onCancel={() => { setShowEditor(false); setEditingTask(null); }}
              />
            )}
          </div>
        )}
        {activeTab === TABS.CALENDAR && (
          <CalendarView
            tasks={tasks}
            onDateClick={handleCalendarDateClick}
            onTaskClick={handleEditTask}
          />
        )}
      </main>
    </div>
  );
}
