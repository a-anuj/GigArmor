import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getWorker, getWorkerClaims, enrollPolicy, simulateTrigger } from '../api';
import { useWorker } from '../context/WorkerContext';
import './Dashboard.css';

const RISK_COLORS = { LOW: '#4ade80', MEDIUM: '#fbbf24', HIGH: '#f87171' };

function riskFromMultiplier(m) {
    if (!m) return 'UNKNOWN';
    if (m <= 1.0) return 'LOW';
    if (m <= 1.3) return 'MEDIUM';
    return 'HIGH';
}

function StatusBadge({ status }) {
    const cfg = {
        'Auto-Approved': { emoji: '✅', color: '#4ade80', label: 'Paid Out' },
        'Soft-Hold': { emoji: '🟡', color: '#fbbf24', label: 'Processing' },
        'Blocked': { emoji: '🔴', color: '#f87171', label: 'Blocked' },
    }[status] ?? { emoji: '⏳', color: '#9b93c0', label: status };
    return (
        <span className="status-badge" style={{ color: cfg.color, borderColor: `${cfg.color}33`, background: `${cfg.color}15` }}>
            {cfg.emoji} {cfg.label}
        </span>
    );
}

export default function Dashboard() {
    const { worker, saveWorker, clearWorker } = useWorker();
    const nav = useNavigate();
    const [profile, setProfile] = useState(null);
    const [claims, setClaims] = useState([]);
    const [enrolling, setEnrolling] = useState(false);
    const [enrollMsg, setEnrollMsg] = useState('');
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!worker) { nav('/onboarding'); return; }
        Promise.all([
            getWorker(worker.id),
            getWorkerClaims(worker.id),
        ]).then(([p, c]) => {
            setProfile(p.data);
            setClaims(c.data.claims || []);
        }).catch(() => { }).finally(() => setLoading(false));
    }, [worker]);

    const handleEnroll = async () => {
        setEnrolling(true);
        setEnrollMsg('');
        try {
            const r = await enrollPolicy(worker.id);
            setEnrollMsg('🛡️ Policy activated! Coverage: ₹1,200');
            setTimeout(() => setEnrollMsg(''), 4000);
        } catch (e) {
            setEnrollMsg(e.response?.data?.detail || 'Enrollment error');
        } finally {
            setEnrolling(false);
        }
    };

    const handleSimulateDemo = async () => {
        setEnrolling(true);
        try {
            await simulateTrigger({ zone_id: profile?.zone?.id ?? 1, event_type: 'Rain', severity: 'High' });
            setEnrollMsg('⚡ Trigger Fired! Claim processing instantaneously...');
            // Reload claims
            const c = await getWorkerClaims(worker.id);
            setClaims(c.data.claims || []);
            setTimeout(() => setEnrollMsg(''), 4000);
        } catch (e) {
            setEnrollMsg('Demo trigger failed');
        } finally {
            setEnrolling(false);
        }
    };

    const risk = riskFromMultiplier(profile?.zone?.base_risk_multiplier);
    const dynamicCoverage = profile?.zone?.base_risk_multiplier ? (profile.zone.base_risk_multiplier * 1000) : 1200;

    if (!worker) return null;
    if (loading) return <div className="screen-loading"><div className="pulse-ring" /><span>Loading...</span></div>;

    const totalPaid = claims.filter(c => c.status === 'Auto-Approved').reduce((s, c) => s + c.payout_amount, 0);

    return (
        <div className="dashboard-screen">
            {/* Top bar */}
            <div className="dash-topbar">
                <div>
                    <div className="dash-welcome">Welcome back</div>
                    <div className="dash-name">Hello, {worker.name.split(' ')[0]} 👋</div>
                </div>
                <button className="logout-btn" onClick={() => { clearWorker(); nav('/onboarding'); }}>↩</button>
            </div>

            {/* Active policy card */}
            <div className="policy-card">
                <div className="policy-card-header">
                    <span className="policy-label">Active Policy</span>
                    <span className="shield-glow">🛡️</span>
                </div>
                <div className="policy-coverage-row">
                    <div>
                        <div className="coverage-label">Coverage</div>
                        <div className="coverage-amount">₹{dynamicCoverage.toLocaleString('en-IN')}</div>
                    </div>
                    <div className="risk-pill" style={{ color: RISK_COLORS[risk], borderColor: `${RISK_COLORS[risk]}44` }}>
                        ● {risk} RISK
                    </div>
                </div>
                <div className="shield-credits-tag">🏆 Shield Credits: Active (20% Discount)</div>
                <div className="policy-actions">
                    <button className="action-btn" onClick={() => nav('/quote')}>
                        Get Quote →
                    </button>
                    <button className="action-btn primary" onClick={handleEnroll} disabled={enrolling}>
                        {enrolling ? '...' : 'Enroll Week'}
                    </button>
                </div>
                {enrollMsg && <div className="enroll-msg">{enrollMsg}</div>}
            </div>

            {/* Wallet Space */}
            <div className="wallet-card">
                <div className="wallet-header">
                    <span className="wallet-title">GigArmor Wallet</span>
                    <span className="trust-badge">{worker.cold_start_active ? '🆕 Cold Start' : '✅ Verified'}</span>
                </div>
                <div className="wallet-balance">
                    ₹{totalPaid.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
                <div className="wallet-subtext">Total Auto-Claim Disbursements ({claims.length} claims)</div>
                <div className="wallet-actions">
                    <button className="wallet-btn withdraw-btn">Withdraw to UPI</button>
                    <button className="wallet-btn demo-trigger-btn" onClick={handleSimulateDemo} disabled={enrolling}>
                        {enrolling ? '...' : '⚡ Mock Rain Event'}
                    </button>
                </div>
            </div>

            {/* Recent payouts */}
            <div className="section-head">
                <span>Recent Payouts</span>
                <span className="zero-touch-tag">Zero-Touch ⚡</span>
            </div>

            {claims.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon">💤</div>
                    <div>No payouts yet. Stay active — triggers fire automatically.</div>
                </div>
            ) : (
                <div className="claims-list">
                    {claims.slice(0, 5).map(c => (
                        <div key={c.id} className="claim-row">
                            <div className="claim-left">
                                <div className="claim-type">{c.event_type ?? 'Parametric Event'} {c.zone_name ? `— ${c.zone_name}` : ''}</div>
                                <div className="claim-date">{new Date(c.created_at).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}</div>
                            </div>
                            <div className="claim-right">
                                <div className="claim-amt" style={{ color: c.status === 'Auto-Approved' ? '#4ade80' : undefined }}>
                                    +₹{c.payout_amount.toLocaleString('en-IN')}
                                </div>
                                <StatusBadge status={c.status} />
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Quick actions */}
            <div className="quick-actions">
                <button className="quick-btn" onClick={() => nav('/quote')}>📊 Quote</button>
                <button className="quick-btn" onClick={() => nav('/claims')}>⚡ Claims</button>
            </div>
        </div>
    );
}
