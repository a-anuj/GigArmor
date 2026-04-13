import { useLocation, useNavigate } from 'react-router-dom';
import { Home, ShieldCheck, Zap } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import './BottomNav.css';

const TABS = [
    { path: '/dashboard', Icon: Home,        key: 'nav.home' },
    { path: '/quote',     Icon: ShieldCheck,  key: 'nav.quote' },
    { path: '/claims',    Icon: Zap,          key: 'nav.claims' },
];

export default function BottomNav() {
    const { pathname } = useLocation();
    const nav = useNavigate();
    const { t } = useTranslation();
    return (
        <nav className="bottom-nav">
            {TABS.map(({ path, Icon, key }) => (
                <button
                    key={path}
                    className={`bottom-tab${pathname === path ? ' active' : ''}`}
                    onClick={() => nav(path)}
                >
                    <span className="tab-icon">
                        <Icon size={22} strokeWidth={pathname === path ? 2.5 : 1.8} />
                    </span>
                    <span className="tab-label">{t(key)}</span>
                </button>
            ))}
        </nav>
    );
}
