import React, { useState, useMemo } from 'react';

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const PRIORITY_COLORS = {
  urgent: '#e74c3c',
  high: '#e67e22',
  medium: '#f1c40f',
  low: '#27ae60',
};

export default function CalendarView({ tasks, onDateClick, onTaskClick }) {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [viewMode, setViewMode] = useState('month');

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const tasksByDate = useMemo(() => {
    const map = {};
    tasks.forEach((t) => {
      if (t.due_date) {
        if (!map[t.due_date]) map[t.due_date] = [];
        map[t.due_date].push(t);
      }
    });
    return map;
  }, [tasks]);

  const calendarDays = useMemo(() => {
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrev = new Date(year, month, 0).getDate();

    const cells = [];

    for (let i = firstDay - 1; i >= 0; i--) {
      const day = daysInPrev - i;
      const d = new Date(year, month - 1, day);
      cells.push({ date: d, day, isCurrentMonth: false });
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const d = new Date(year, month, day);
      cells.push({ date: d, day, isCurrentMonth: true });
    }

    const remaining = 42 - cells.length;
    for (let day = 1; day <= remaining; day++) {
      const d = new Date(year, month + 1, day);
      cells.push({ date: d, day, isCurrentMonth: false });
    }

    return cells;
  }, [year, month]);

  const formatDateKey = (d) => {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${dd}`;
  };

  const isToday = (d) => {
    const today = new Date();
    return d.getDate() === today.getDate() &&
           d.getMonth() === today.getMonth() &&
           d.getFullYear() === today.getFullYear();
  };

  const prevMonth = () => setCurrentDate(new Date(year, month - 1, 1));
  const nextMonth = () => setCurrentDate(new Date(year, month + 1, 1));
  const goToday = () => setCurrentDate(new Date());

  const selectedDateKey = formatDateKey(currentDate);
  const dayTasks = tasksByDate[selectedDateKey] || [];

  return (
    <div className="calendar-view">
      <div className="calendar-header">
        <div className="calendar-nav">
          <button className="btn btn-icon" onClick={prevMonth}>&lsaquo;</button>
          <h2>{MONTHS[month]} {year}</h2>
          <button className="btn btn-icon" onClick={nextMonth}>&rsaquo;</button>
        </div>
        <div className="calendar-actions">
          <button className="btn btn-secondary btn-sm" onClick={goToday}>Today</button>
          <div className="view-toggle">
            <button
              className={`filter-btn ${viewMode === 'month' ? 'active' : ''}`}
              onClick={() => setViewMode('month')}
            >
              Month
            </button>
            <button
              className={`filter-btn ${viewMode === 'day' ? 'active' : ''}`}
              onClick={() => setViewMode('day')}
            >
              Day
            </button>
          </div>
        </div>
      </div>

      {viewMode === 'month' ? (
        <div className="calendar-grid">
          <div className="calendar-weekdays">
            {DAYS.map((d) => (
              <div key={d} className="weekday">{d}</div>
            ))}
          </div>
          <div className="calendar-cells">
            {calendarDays.map((cell, i) => {
              const dateKey = formatDateKey(cell.date);
              const cellTasks = tasksByDate[dateKey] || [];
              return (
                <div
                  key={i}
                  className={`calendar-cell ${cell.isCurrentMonth ? '' : 'other-month'} ${isToday(cell.date) ? 'today' : ''} ${dateKey === selectedDateKey ? 'selected' : ''}`}
                  onClick={() => {
                    setCurrentDate(cell.date);
                    if (cellTasks.length === 0) onDateClick(dateKey);
                  }}
                >
                  <span className="cell-day">{cell.day}</span>
                  <div className="cell-tasks">
                    {cellTasks.slice(0, 3).map((t) => (
                      <div
                        key={t.id}
                        className={`cell-task ${t.completed ? 'completed' : ''}`}
                        style={{ borderLeftColor: PRIORITY_COLORS[t.priority] || PRIORITY_COLORS.medium }}
                        onClick={(e) => { e.stopPropagation(); onTaskClick(t); }}
                        title={t.title}
                      >
                        {t.title.length > 15 ? t.title.substring(0, 15) + '...' : t.title}
                      </div>
                    ))}
                    {cellTasks.length > 3 && (
                      <span className="cell-more">+{cellTasks.length - 3} more</span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ) : (
        <div className="day-view">
          <h3 className="day-view-date">
            {currentDate.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
          </h3>
          {dayTasks.length === 0 ? (
            <div className="empty-state">
              <p>No tasks on this day.</p>
              <button className="btn btn-primary" onClick={() => onDateClick(selectedDateKey)}>
                + Add Task
              </button>
            </div>
          ) : (
            <div className="day-task-list">
              {dayTasks.map((t) => (
                <div
                  key={t.id}
                  className={`day-task-item ${t.completed ? 'completed' : ''}`}
                  onClick={() => onTaskClick(t)}
                >
                  <span
                    className="priority-bar"
                    style={{ backgroundColor: PRIORITY_COLORS[t.priority] }}
                  />
                  <div className="day-task-info">
                    <strong>{t.title}</strong>
                    {t.description && <p>{t.description}</p>}
                    {t.tags && (
                      <div className="task-tags">
                        {t.tags.split(',').map((tag) => (
                          <span key={tag.trim()} className="tag">{tag.trim()}</span>
                        ))}
                      </div>
                    )}
                  </div>
                  <span className={`status-badge ${t.completed ? 'done' : 'pending'}`}>
                    {t.completed ? 'Done' : 'Pending'}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
