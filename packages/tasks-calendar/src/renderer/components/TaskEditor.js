import React, { useState, useEffect, useRef } from 'react';

function generateId() {
  return 'task_' + Date.now().toString(36) + '_' + Math.random().toString(36).substring(2, 8);
}

export default function TaskEditor({ task, onSave, onDelete, onCancel }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [dueDate, setDueDate] = useState('');
  const [priority, setPriority] = useState('medium');
  const [tags, setTags] = useState('');
  const titleRef = useRef(null);

  useEffect(() => {
    if (task) {
      setTitle(task.title || '');
      setDescription(task.description || '');
      setDueDate(task.due_date || '');
      setPriority(task.priority || 'medium');
      setTags(task.tags || '');
    } else {
      setTitle('');
      setDescription('');
      setDueDate('');
      setPriority('medium');
      setTags('');
    }
    if (titleRef.current) titleRef.current.focus();
  }, [task]);

  useEffect(() => {
    const handleSave = () => handleSubmit();
    window.electronAPI.onSave(handleSave);
    return () => window.electronAPI.removeListener('shortcut:save', handleSave);
  });

  const handleSubmit = (e) => {
    if (e) e.preventDefault();
    if (!title.trim()) return;

    const taskData = {
      id: task?.id || generateId(),
      title: title.trim(),
      description: description.trim(),
      due_date: dueDate || null,
      priority,
      tags: tags.trim(),
      completed: task?.completed || 0,
    };

    onSave(taskData);
  };

  return (
    <div className="task-editor-overlay" onClick={onCancel}>
      <div className="task-editor" onClick={(e) => e.stopPropagation()}>
        <div className="editor-header">
          <h3>{task?.id ? 'Edit Task' : 'New Task'}</h3>
          <button className="btn-icon" onClick={onCancel} aria-label="Close">&times;</button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="task-title">Title</label>
            <input
              ref={titleRef}
              id="task-title"
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="What needs to be done?"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="task-description">Description</label>
            <textarea
              id="task-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Add details..."
              rows={3}
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="task-due">Due Date</label>
              <input
                id="task-due"
                type="date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label htmlFor="task-priority">Priority</label>
              <select
                id="task-priority"
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
              >
                <option value="low">Low</option>
                <option value="medium">Medium</option>
                <option value="high">High</option>
                <option value="urgent">Urgent</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="task-tags">Tags (comma-separated)</label>
            <input
              id="task-tags"
              type="text"
              value={tags}
              onChange={(e) => setTags(e.target.value)}
              placeholder="homework, math, chapter-5"
            />
          </div>

          <div className="editor-actions">
            <button type="submit" className="btn btn-primary">
              {task?.id ? 'Update' : 'Create'} Task
            </button>
            {onDelete && (
              <button
                type="button"
                className="btn btn-danger"
                onClick={() => onDelete(task.id)}
              >
                Delete
              </button>
            )}
            <button type="button" className="btn btn-secondary" onClick={onCancel}>
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
