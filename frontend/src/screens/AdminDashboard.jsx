import { useEffect, useState } from 'react';
import { getPlatformStats, getTriggers, simulateTrigger, listWorkers, getZones } from '../api';
import './AdminDashboard.css';

const SEVERITIES = ['Moderate', 'High', 'Critical'];
const EVENT_TYPES = ['Rain', 'AQI', 'Outage', 'Social', 'Heat'];
const EVENT_ICONS = { Rain: '🌧️', AQI: '🌫️', Outage: '📡', Social: '🚫', Heat: '🌡️' };

function riskColor(r) {
    if (r <= 1.0) return '#4ade80';
    if (r <= 1.2) return '#fbbf24';
    if (r <= 1.4) return '#fb923c';
    return '#f87171';
}
function riskLabel(r) {
    if (r <= 1.0) return 'LOW';
    if (r <= 1.2) return 'MED';
    if (r <= 1.4) return 'HIGH';
    return '🔥 CRITICAL';
}

export default function AdminDashboard() {
    const [stats, setStats] = useState(null);
    const [triggers, setTriggers] = useState([]);
    const [workers, setWorkers] = useState([]);
    const [zones, setZones] = useState([]);
    const [simZone, setSimZone] = useState(1);
    const [simType, setSimType] = useState('Rain');
    const [simSev, setSimSev] = useState('Moderate');
    const [simResult, setSimResult] = useState(null);
    const [simLoading, setSimLoading] = useState(false);
    const [lastRefresh, setLastRefresh] = useState(new Date());

    const load = () => {
        Promise.all([getPlatformStats(), getTriggers(), listWorkers(), getZones()])
            .then(([s, t, w, z]) => {
                setStats(s.data);
                setTriggers(t.data.slice(0, 10));
                setWorkers(w.data.workers || []);
                setZones(z.data || []);
                setLastRefresh(new Date());
            })
            .catch(() => { });
    };

    useEffect(() => { load(); const id = setInterval(load, 15000); return () => clearInterval(id); }, []);

    const handleSimulate = async () => {
        setSimLoading(true);
        setSimResult(null);
        try {
            const r = await simulateTrigger({ zone_id: parseInt(simZone) || (zones[0]?.id ?? 1), event_type: simType, severity: simSev });
            setSimResult(r.data);
            load(); // Refresh stats
        } catch (e) {
            setSimResult({ error: e.response?.data?.detail || 'Simulation failed' });
        } finally {
            setSimLoading(false);
        }
    };

    return (
        <div className="admin-shell">
            {/* Sidebar */}
            <aside className="admin-sidebar">
                <div className="admin-brand">🛡️ HustleHalt</div>
                <nav className="admin-nav">
                    {['Dashboard', 'Risk Analysis', 'Policy Engine', 'System Logs'].map(l => (
                        <div key={l} className={`admin-nav-item${l === 'Dashboard' ? ' active' : ''}`}>{l}</div>
                    ))}
                </nav>
                <div className="sidebar-footer">
                    <a href="/" className="back-to-app">← Worker App</a>
                </div>
            </aside>

            {/* Main content */}
            <main className="admin-main">
                <div className="admin-content-wrapper">
                    {/* Top bar */}
                    <div className="admin-topbar">
                        <div>
                            <h1 className="admin-page-title">Admin &amp; Demo Command Center</h1>
                            <p className="admin-page-sub">Real-time parametric insurance oversight · Auto-refreshes every 15s · Last: {lastRefresh.toLocaleTimeString()}</p>
                        </div>
                        <button className="refresh-btn" onClick={load}>🔄 Refresh</button>
                    </div>

                    {/* Stats grid */}
                    <div className="stats-grid">
                        {[
                            { label: 'Total Workers', val: stats?.workers?.total ?? '—', icon: '👥', sub: `${stats?.workers?.active ?? '—'} active` },
                            { label: 'Active Policies', val: stats?.policies?.active ?? '—', icon: '📋', sub: `${stats?.policies?.expired ?? '—'} expired` },
                            { label: 'Total Payouts', val: `₹${(stats?.claims?.total_payout ?? 0).toLocaleString('en-IN')}`, icon: '💸', sub: `${stats?.claims?.auto_approved ?? '—'} auto-approved` },
                            { label: 'Auto-Approval Rate', val: stats?.claims?.total ? `${Math.round((stats.claims.auto_approved / stats.claims.total) * 100)}%` : '—', icon: '✅', sub: `${stats?.claims?.soft_hold ?? 0} soft-hold, ${stats?.claims?.blocked ?? 0} blocked` },
                        ].map(s => (
                            <div className="stat-card" key={s.label}>
                                <div className="stat-card-icon">{s.icon}</div>
                                <div className="stat-card-val">{s.val}</div>
                                <div className="stat-card-label">{s.label}</div>
                                <div className="stat-card-sub">{s.sub}</div>
                            </div>
                        ))}
                    </div>

                    <div className="admin-columns">
                        {/* Left column */}
                        <div className="admin-col">
                            {/* Zone Risk Map */}
                            <div className="admin-card">
                                <div className="card-title">📍 Zone Risk Map</div>
                                <div className="zone-grid-admin">
                                    {(zones || []).map(z => {
                                        const zRisk = z.base_risk_multiplier ?? 1.0;
                                        const matched = triggers.filter(t => t.zone_id === z.id);
                                        return (
                                            <div className="zone-tile" key={z.id} style={{ borderColor: `${riskColor(zRisk)}44` }}>
                                                <div className="zone-tile-name">{z.name}</div>
                                                <div className="zone-tile-risk" style={{ color: riskColor(zRisk) }}>{riskLabel(zRisk)}</div>
                                                <div className="zone-tile-pin">{z.pincode}</div>
                                                {matched.length > 0 && <div className="zone-tile-alert">⚡ {matched.length} trigger(s)</div>}
                                            </div>
                                        );
                                    })}
                                </div>
                            </div>

                            {/* Workers table */}
                            <div className="admin-card">
                                <div className="card-title">👥 Registered Workers</div>
                                {workers.length === 0 ? (
                                    <div className="admin-empty">No workers registered yet. Use the Worker App to onboard.</div>
                                ) : (
                                    <table className="admin-table">
                                        <thead>
                                            <tr><th>ID</th><th>Name</th><th>Zone</th><th>Trust</th><th>Status</th></tr>
                                        </thead>
                                        <tbody>
                                            {workers.map(w => (
                                                <tr key={w.id}>
                                                    <td>#{w.id}</td>
                                                    <td>{w.name}</td>
                                                    <td>Zone {w.zone_id}</td>
                                                    <td>
                                                        <div className="trust-mini">
                                                            <div className="trust-mini-bar" style={{ width: `${w.trust_baseline_score}%`, background: w.trust_baseline_score >= 75 ? '#4ade80' : '#fbbf24' }} />
                                                            <span>{w.trust_baseline_score}</span>
                                                        </div>
                                                    </td>
                                                    <td><span className={`status-dot ${w.status.toLowerCase()}`}>{w.status}</span></td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                )}
                            </div>
                        </div>

                        {/* Right column */}
                        <div className="admin-col">
                            {/* Trigger Simulator */}
                            <div className="admin-card simulator-card">
                                <div className="card-title">⚡ Trigger Simulator <span className="demo-tag">Demo Mode</span></div>
                                <p className="card-desc">Force-fire a parametric trigger. Claims process in real-time to show the zero-touch flow.</p>

                                <div className="sim-form">
                                    <div className="sim-row">
                                        <label>Zone</label>
                                        <select value={simZone} onChange={e => setSimZone(e.target.value)}>
                                            {(zones || []).map(z => <option key={z.id} value={z.id}>{z.name}</option>)}
                                        </select>
                                    </div>
                                    <div className="sim-row">
                                        <label>Event Type</label>
                                        <div className="type-chips">
                                            {EVENT_TYPES.map(t => (
                                                <button key={t} className={`type-chip${simType === t ? ' active' : ''}`} onClick={() => setSimType(t)}>
                                                    {EVENT_ICONS[t]} {t}
                                                </button>
                                            ))}
                                        </div>
                                    </div>
                                    <div className="sim-row">
                                        <label>Severity</label>
                                        <div className="type-chips">
                                            {SEVERITIES.map(s => (
                                                <button key={s} className={`type-chip${simSev === s ? ' active' : ''}`} onClick={() => setSimSev(s)}>
                                                    {s}
                                                </button>
                                            ))}
                                        </div>
                                    </div>
                                </div>

                                <button className="sim-fire-btn" onClick={handleSimulate} disabled={simLoading}>
                                    {simLoading ? '⏳ Firing...' : '🚀 Fire Trigger'}
                                </button>

                                {simResult && !simResult.error && (
                                    <div className="sim-result">
                                        <div className="sim-result-title">✅ Trigger Fired — {simResult.zone_name}</div>
                                        <div className="sim-result-grid">
                                            <span>Claims processed</span><strong>{simResult.claims_generated ?? 0}</strong>
                                            <span>Auto-approved</span><strong style={{ color: '#4ade80' }}>{simResult.auto_approved ?? 0}</strong>
                                            <span>Soft-held</span><strong style={{ color: '#fbbf24' }}>{simResult.soft_hold ?? 0}</strong>
                                            <span>Blocked</span><strong style={{ color: '#f87171' }}>{simResult.blocked ?? 0}</strong>
                                            <span>Total payout</span><strong>₹{(simResult.total_payout ?? 0).toLocaleString('en-IN')}</strong>
                                        </div>
                                    </div>
                                )}
                                {simResult?.error && <div className="sim-error">⚠ {simResult.error}</div>}
                            </div>

                            {/* Recent triggers */}
                            <div className="admin-card">
                                <div className="card-title">📋 Recent Trigger Events</div>
                                {triggers.length === 0 ? (
                                    <div className="admin-empty">No triggers yet. Use the simulator above.</div>
                                ) : (
                                    <div className="trigger-list">
                                        {triggers.map(t => (
                                            <div className="trigger-row" key={t.id}>
                                                <span className="trigger-icon">{EVENT_ICONS[t.event_type] ?? '⚡'}</span>
                                                <div className="trigger-info">
                                                    <div className="trigger-type">{t.event_type} — {t.zone_name}</div>
                                                    <div className="trigger-ts">{new Date(t.start_time).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}</div>
                                                </div>
                                                <span className="trigger-sev">{t.severity}</span>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </main >
        </div >
    );
}
