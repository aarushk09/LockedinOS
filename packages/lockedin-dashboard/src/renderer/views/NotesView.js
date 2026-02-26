import React, { useState, useEffect, useCallback } from 'react';
import { v4 as uuidv4 } from 'uuid';

export default function NotesView() {
  const [notes, setNotes] = useState([]);
  const [activeNote, setActiveNote] = useState(null);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');

  const loadNotes = useCallback(async () => {
    const all = await window.electronAPI.notes.getAll();
    setNotes(all);
  }, []);

  useEffect(() => { loadNotes(); }, [loadNotes]);

  const selectNote = (note) => {
    setActiveNote(note);
    setTitle(note.title);
    setContent(note.content);
  };

  const handleNew = async () => {
    const note = await window.electronAPI.notes.create({ id: uuidv4(), title: 'Untitled Note', content: '' });
    await loadNotes();
    selectNote(note);
  };

  const handleSave = async () => {
    if (!activeNote) return;
    await window.electronAPI.notes.update({ id: activeNote.id, title, content });
    await loadNotes();
  };

  const handleDelete = async () => {
    if (!activeNote) return;
    await window.electronAPI.notes.delete(activeNote.id);
    setActiveNote(null);
    setTitle('');
    setContent('');
    await loadNotes();
  };

  return (
    <div className="notes-view">
      <div className="notes-sidebar">
        <div className="notes-sidebar-header">
          <h2>Notes</h2>
          <button className="btn btn-primary btn-sm" onClick={handleNew}>+ New</button>
        </div>
        <div className="notes-list">
          {notes.map(n => (
            <button
              key={n.id}
              className={`note-item ${activeNote?.id === n.id ? 'active' : ''}`}
              onClick={() => selectNote(n)}
            >
              <strong>{n.title}</strong>
              <small>{n.content?.substring(0, 60) || 'Empty note'}</small>
            </button>
          ))}
          {notes.length === 0 && <p className="empty-hint">No notes yet. Create one!</p>}
        </div>
      </div>
      <div className="notes-editor">
        {activeNote ? (
          <>
            <div className="notes-editor-header">
              <input
                type="text"
                className="input notes-title-input"
                value={title}
                onChange={e => setTitle(e.target.value)}
                onBlur={handleSave}
                placeholder="Note title..."
              />
              <div className="notes-actions">
                <button className="btn btn-ghost btn-sm" onClick={handleSave}>Save</button>
                <button className="btn btn-danger btn-sm" onClick={handleDelete}>Delete</button>
              </div>
            </div>
            <textarea
              className="notes-content-area"
              value={content}
              onChange={e => setContent(e.target.value)}
              onBlur={handleSave}
              placeholder="Start writing..."
            />
          </>
        ) : (
          <div className="notes-empty">
            <p>Select a note or create a new one</p>
          </div>
        )}
      </div>
    </div>
  );
}
