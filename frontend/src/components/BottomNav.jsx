import { useLocation, useNavigate } from 'react-router-dom';
import './BottomNav.css';

const TABS = [
    { path: '/dashboard', icon: '🏠', label: 'Home' },
    { path: '/quote', icon: '🛡️', label: 'Quote' },
    { path: '/claims', icon: '⚡', label: 'Claims' },
];

export default function BottomNav() {
    const { pathname } = useLocation();
    const nav = useNavigate();
    return (
        <nav className="bottom-nav">
            {TABS.map((t) => (
                <button
                    key={t.path}
                    className={`bottom-tab${pathname === t.path ? ' active' : ''}`}
                    onClick={() => nav(t.path)}
                >
                    <span className="tab-icon">{t.icon}</span>
                    <span className="tab-label">{t.label}</span>
                </button>
            ))}
        </nav>
    );
}
