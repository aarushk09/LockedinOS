import React, { useState } from 'react';

const PRIORITY_COLORS = {
  urgent: '#e74c3c',
  high: '#e67e22',
  medium: '#f1c40f',
  low: '#27ae60',
};

const FILTERS = ['all', 'active', 'completed'];

export default function TaskList({ tasks, onEdit, onToggleComplete, onNewTask }) {
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  const filteredTasks = tasks.filter((t) => {
    if (filter === 'active' && t.completed) return false;
    if (filter === 'completed' && !t.completed) return false;
    if (search && !t.title.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const formatDate = (dateStr) => {
    if (!dateStr) return '';
    const d = new Date(dateStr + 'T00:00:00');
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  const isOverdue = (task) => {
    if (!task.due_date || task.completed) return false;
    return new Date(task.due_date + 'T23:59:59') < new Date();
  };

  return (
    <div className="task-list-panel">
      <div className="task-list-header">
        <h2>My Tasks</h2>
        <button className="btn btn-primary" onClick={onNewTask}>
          + New Task
        </button>
      </div>

      <div className="task-list-controls">
        <input
          type="text"
          className="search-input"
          placeholder="Search tasks..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div className="filter-btns">
          {FILTERS.map((f) => (
            <button
              key={f}
              className={`filter-btn ${filter === f ? 'active' : ''}`}
              onClick={() => setFilter(f)}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="task-list">
        {filteredTasks.length === 0 && (
          <div className="empty-state">
            <p>No tasks found. Click "+ New Task" to get started.</p>
          </div>
        )}
        {filteredTasks.map((task) => (
          <div
            key={task.id}
            className={`task-item ${task.completed ? 'completed' : ''} ${isOverdue(task) ? 'overdue' : ''}`}
            onClick={() => onEdit(task)}
          >
            <button
              className="task-checkbox"
              onClick={(e) => { e.stopPropagation(); onToggleComplete(task); }}
              aria-label={task.completed ? 'Mark incomplete' : 'Mark complete'}
            >
              {task.completed ? '✓' : ''}
            </button>
            <div className="task-info">
              <span className="task-title">{task.title}</span>
              <div className="task-meta">
                {task.due_date && (
                  <span className={`task-due ${isOverdue(task) ? 'overdue-text' : ''}`}>
                    {formatDate(task.due_date)}
                  </span>
                )}
                {task.tags && (
                  <span className="task-tags">
                    {task.tags.split(',').map((tag) => (
                      <span key={tag.trim()} className="tag">{tag.trim()}</span>
                    ))}
                  </span>
                )}
              </div>
            </div>
            <span
              className="priority-dot"
              style={{ backgroundColor: PRIORITY_COLORS[task.priority] || PRIORITY_COLORS.medium }}
              title={task.priority}
            />
          </div>
        ))}
      </div>
    </div>
  );
}
