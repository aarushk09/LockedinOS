import React, { useState, useEffect, useCallback } from 'react';
import { v4 as uuidv4 } from 'uuid';

const PRIORITY_COLORS = { high: '#e74c3c', medium: '#f39c12', low: '#27ae60' };

export default function DashboardView() {
  const [tasks, setTasks] = useState([]);
  const [subTab, setSubTab] = useState('tasks');
  const [showAddTask, setShowAddTask] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newPriority, setNewPriority] = useState('medium');
  const [newDueDate, setNewDueDate] = useState('');
  const [focusActive, setFocusActive] = useState(false);
  const [calendarDate, setCalendarDate] = useState(new Date());

  const loadTasks = useCallback(async () => {
    const all = await window.electronAPI.tasks.getAll();
    setTasks(all);
  }, []);

  useEffect(() => {
    loadTasks();
    window.electronAPI.focus.getStatus().then(s => setFocusActive(s.active)).catch(() => {});
  }, [loadTasks]);

  const handleAddTask = async () => {
    if (!newTitle.trim()) return;
    await window.electronAPI.tasks.create({
      id: uuidv4(),
      title: newTitle.trim(),
      priority: newPriority,
      due_date: newDueDate || null,
      completed: 0,
    });
    setNewTitle('');
    setNewPriority('medium');
    setNewDueDate('');
    setShowAddTask(false);
    await loadTasks();
  };

  const handleToggle = async (task) => {
    await window.electronAPI.tasks.update({ ...task, completed: task.completed ? 0 : 1 });
    await loadTasks();
  };

  const handleDelete = async (id) => {
    await window.electronAPI.tasks.delete(id);
    await loadTasks();
  };

  const today = new Date().toISOString().split('T')[0];
  const todayTasks = tasks.filter(t => !t.completed && t.due_date === today);
  const upcomingTasks = tasks.filter(t => !t.completed && t.due_date && t.due_date > today);
  const completedTasks = tasks.filter(t => t.completed);
  const overdueTasks = tasks.filter(t => !t.completed && t.due_date && t.due_date < today);

  // Calendar helpers
  const year = calendarDate.getFullYear();
  const month = calendarDate.getMonth();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const firstDay = new Date(year, month, 1).getDay();
  const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  const calendarCells = [];
  for (let i = 0; i < firstDay; i++) calendarCells.push(null);
  for (let d = 1; d <= daysInMonth; d++) calendarCells.push(d);

  const prevMonth = () => setCalendarDate(new Date(year, month - 1, 1));
  const nextMonth = () => setCalendarDate(new Date(year, month + 1, 1));

  return (
    <div className="dashboard-view">
      <div className="dashboard-main">
        <div className="panel tasks-panel">
          <h2 className="panel-title">Tasks & Calendar</h2>
          <div className="sub-tabs">
            <button className={`sub-tab ${subTab === 'tasks' ? 'active' : ''}`} onClick={() => setSubTab('tasks')}>Tasks</button>
            <button className={`sub-tab ${subTab === 'calendar' ? 'active' : ''}`} onClick={() => setSubTab('calendar')}>Calendar</button>
          </div>

          {subTab === 'tasks' && (
            <div className="tasks-content">
              {overdueTasks.length > 0 && (
                <div className="task-section">
                  <h3 className="section-label overdue-label">⚠ Overdue</h3>
                  {overdueTasks.map(t => (
                    <TaskItem key={t.id} task={t} onToggle={handleToggle} onDelete={handleDelete} />
                  ))}
                </div>
              )}
              <div className="task-section">
                <h3 className="section-label">▽ Today</h3>
                {todayTasks.length === 0 && <p className="empty-hint">No tasks due today</p>}
                {todayTasks.map(t => (
                  <TaskItem key={t.id} task={t} onToggle={handleToggle} onDelete={handleDelete} />
                ))}
              </div>
              <div className="task-section">
                <h3 className="section-label">▽ Upcoming</h3>
                {upcomingTasks.map(t => (
                  <TaskItem key={t.id} task={t} onToggle={handleToggle} onDelete={handleDelete} />
                ))}
              </div>
              {completedTasks.length > 0 && (
                <div className="task-section">
                  <h3 className="section-label completed-label">▽ Completed</h3>
                  {completedTasks.slice(0, 5).map(t => (
                    <TaskItem key={t.id} task={t} onToggle={handleToggle} onDelete={handleDelete} />
                  ))}
                </div>
              )}

              {showAddTask ? (
                <div className="add-task-form">
                  <input
                    type="text"
                    placeholder="Task title..."
                    value={newTitle}
                    onChange={e => setNewTitle(e.target.value)}
                    onKeyDown={e => e.key === 'Enter' && handleAddTask()}
                    autoFocus
                    className="input"
                  />
                  <div className="add-task-row">
                    <input type="date" value={newDueDate} onChange={e => setNewDueDate(e.target.value)} className="input input-date" />
                    <select value={newPriority} onChange={e => setNewPriority(e.target.value)} className="input input-select">
                      <option value="high">High</option>
                      <option value="medium">Medium</option>
                      <option value="low">Low</option>
                    </select>
                    <button className="btn btn-primary" onClick={handleAddTask}>Add</button>
                    <button className="btn btn-ghost" onClick={() => setShowAddTask(false)}>Cancel</button>
                  </div>
                </div>
              ) : (
                <button className="btn btn-add-task" onClick={() => setShowAddTask(true)}>+ New Task</button>
              )}
            </div>
          )}

          {subTab === 'calendar' && (
            <div className="calendar-content">
              <div className="cal-nav">
                <button className="btn btn-ghost cal-arrow" onClick={prevMonth}>‹</button>
                <span className="cal-month">{monthNames[month]} {year} ▾</span>
                <button className="btn btn-ghost cal-arrow" onClick={nextMonth}>›</button>
              </div>
              <div className="cal-grid">
                {dayNames.map(d => <div key={d} className="cal-day-header">{d}</div>)}
                {calendarCells.map((day, i) => {
                  if (day === null) return <div key={`e-${i}`} className="cal-cell empty" />;
                  const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
                  const isToday = dateStr === today;
                  const hasTasks = tasks.some(t => t.due_date === dateStr);
                  return (
                    <div key={day} className={`cal-cell ${isToday ? 'today' : ''} ${hasTasks ? 'has-tasks' : ''}`}>
                      <span className="cal-day-num">{day}</span>
                      {hasTasks && <span className="cal-dot" />}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="dashboard-side">
        <div className="panel study-tools-panel">
          <h2 className="panel-title">Study Tools</h2>
          <div className="tools-grid">
            <ToolCard icon="📝" name="Notes" color="#3498db" onClick={() => window.electronAPI.system.launchApp('gnome-text-editor')} />
            <ToolCard icon="❓" name="Flashcards" color="#9b59b6" onClick={() => {}} />
            <ToolCard icon="🔢" name="Calculator" color="#2c3e50" onClick={() => window.electronAPI.system.launchApp('gnome-calculator')} />
            <ToolCard icon="⏳" name="Timer" color="#e67e22" onClick={() => window.electronAPI.system.launchApp('gnome-clocks')} />
          </div>
        </div>

        <div className="panel system-info-panel">
          <h2 className="panel-title">System Info</h2>
          <div className="info-list">
            <InfoRow icon={focusActive ? '✅' : '⭕'} label="Focus Mode" value={focusActive ? 'Active' : 'Inactive'} active={focusActive} />
            <InfoRow icon="🛡" label="Website Blocker" value={focusActive ? 'Enabled' : 'Disabled'} active={focusActive} />
            <InfoRow icon="💾" label="Automatic Backups" value="On" active={true} />
          </div>
        </div>
      </div>
    </div>
  );
}

function TaskItem({ task, onToggle, onDelete }) {
  const isOverdue = !task.completed && task.due_date && task.due_date < new Date().toISOString().split('T')[0];
  return (
    <div className={`task-item ${task.completed ? 'completed' : ''} ${isOverdue ? 'overdue' : ''}`}>
      <button className={`task-check ${task.completed ? 'checked' : ''}`} onClick={() => onToggle(task)}>
        {task.completed ? '✓' : ''}
      </button>
      <div className="task-info">
        <span className="task-title">{task.title}</span>
        <div className="task-meta-row">
          {task.priority && (
            <span className={`priority-badge priority-${task.priority}`}>{task.priority.charAt(0).toUpperCase() + task.priority.slice(1)}</span>
          )}
          {isOverdue && <span className="due-badge overdue-badge">Overdue</span>}
          {task.due_date && !isOverdue && task.due_date === new Date().toISOString().split('T')[0] && (
            <span className="due-badge today-badge">Due Today</span>
          )}
        </div>
      </div>
      <button className="task-delete-btn" onClick={() => onDelete(task.id)} title="Delete">✕</button>
    </div>
  );
}

function ToolCard({ icon, name, color, onClick }) {
  return (
    <button className="tool-card" onClick={onClick} style={{ '--tool-color': color }}>
      <span className="tool-icon">{icon}</span>
      <span className="tool-name">{name}</span>
    </button>
  );
}

function InfoRow({ icon, label, value, active }) {
  return (
    <div className="info-row">
      <span className="info-icon">{icon}</span>
      <span className="info-label">{label}</span>
      <span className={`info-value ${active ? 'active' : ''}`}>{value}</span>
    </div>
  );
}
