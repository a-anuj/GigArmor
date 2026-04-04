import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import BottomNav from './BottomNav';
import './AppLayout.css';

export default function AppLayout() {
    const nav = useNavigate();
    const { pathname } = useLocation();
    const isOnboarding = pathname === '/onboarding';

    return (
        <div className="app-shell">
            {/* Desktop label */}
            <div className="app-label">
                <span className="shield-icon">🛡️</span>
                <span>GigArmor</span>
                <span className="app-label-sub">Worker App Demo</span>
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
                ⚙️ Admin Dashboard →
            </a>
        </div>
    );
}
