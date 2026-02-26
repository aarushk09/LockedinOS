import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles/theme.css';
import './styles/layout.css';
import './styles/components.css';

const root = createRoot(document.getElementById('root'));
root.render(<App />);
