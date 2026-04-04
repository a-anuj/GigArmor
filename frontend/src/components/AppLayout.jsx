import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { ShieldCheck, Settings, Globe } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import BottomNav from './BottomNav';
import './AppLayout.css';

const LANGUAGES = [
    { code: 'en', label: 'EN' },
    { code: 'ta', label: 'தமிழ்' },
    { code: 'hi', label: 'हिंदी' },
];

export default function AppLayout() {
    const nav = useNavigate();
    const { pathname } = useLocation();
    const { i18n } = useTranslation();
    const isOnboarding = pathname === '/onboarding';

    const cycleLang = () => {
        const langs = LANGUAGES.map(l => l.code);
        const idx = langs.indexOf(i18n.language);
        const next = langs[(idx + 1) % langs.length];
        i18n.changeLanguage(next);
        localStorage.setItem('hustlehalt_lang', next);
    };

    const currentLang = LANGUAGES.find(l => l.code === i18n.language) ?? LANGUAGES[0];

    return (
        <div className="app-shell">
            {/* Desktop header row */}
            <div className="app-top-row">
                <div className="app-label">
                    <img src="/logo.png" alt="Logo" style={{ height: '24px', marginRight: '6px' }} />
                    <span>HustleHalt</span>
                    <span className="app-label-sub">Worker App Demo</span>
                </div>
                <button className="lang-toggle" onClick={cycleLang} title="Switch language">
                    <Globe size={14} />
                    {currentLang.label}
                </button>
            </div>

            {/* Phone frame */}
            <div className="phone-frame">
                <div className="phone-notch" />
                <div className="phone-screen">
                    <Outlet />
                </div>
                {!isOnboarding && <BottomNav />}
                <div className="phone-home-bar" />
            </div>

            {/* Admin link */}
            <a href="/admin" className="admin-pill" target="_blank" rel="noreferrer">
                <Settings size={14} />
                Admin Dashboard
            </a>
        </div>
    );
}
