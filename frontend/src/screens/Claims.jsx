import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getWorkerClaims } from '../api';
import { useWorker } from '../context/WorkerContext';
import './Claims.css';

const STATUS_CFG = {
    'Auto-Approved': { emoji: '✅', color: '#4ade80', label: 'Auto-Approved · Paid Out' },
    'Soft-Hold': { emoji: '🟡', color: '#fbbf24', label: 'Processing · Passive Re-verify' },
    'Blocked': { emoji: '🔴', color: '#f87171', label: 'Blocked · Appeal Window 72h' },
};
const EVENT_EMOJI = {
    Rain: '🌧️', AQI: '🌫️', Outage: '📡', Social: '🚫', Heat: '🌡️',
};

export default function Claims() {
    const { worker } = useWorker();
    const nav = useNavigate();
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('all');

    useEffect(() => {
        if (!worker) { nav('/onboarding'); return; }
        getWorkerClaims(worker.id)
            .then(r => setData(r.data))
            .finally(() => setLoading(false));
    }, [worker]);

    if (!worker) return null;
    if (loading) return <div className="screen-loading"><div className="pulse-ring" /><span>Loading claims…</span></div>;

    const claims = data?.claims ?? [];
    const filtered = filter === 'all' ? claims : claims.filter(c => c.status === filter);

    return (
        <div className="claims-screen">
            <div className="claims-topbar">
                <div className="claims-title">⚡ Claims Feed</div>
                <div className="zero-touch-badge">Zero-Touch</div>
            </div>

            {/* Summary row */}
            <div className="claims-summary">
                <div className="sum-box">
                    <div className="sum-val">₹{(data?.total_payout ?? 0).toLocaleString('en-IN')}</div>
                    <div className="sum-key">Total Received</div>
                </div>
                <div className="sum-box">
                    <div className="sum-val">{data?.total_claims ?? 0}</div>
                    <div className="sum-key">Total Claims</div>
                </div>
                <div className="sum-box">
                    <div className="sum-val">{claims.filter(c => c.status === 'Auto-Approved').length}</div>
                    <div className="sum-key">Auto-Approved</div>
                </div>
            </div>

            {/* Filter chips */}
            <div className="filter-chips">
                {['all', 'Auto-Approved', 'Soft-Hold', 'Blocked'].map(f => (
                    <button
                        key={f}
                        className={`chip${filter === f ? ' active' : ''}`}
                        onClick={() => setFilter(f)}
                    >
                        {f === 'all' ? 'All' : STATUS_CFG[f]?.emoji + ' ' + f.replace('-', ' ')}
                    </button>
                ))}
            </div>

            {/* Claims list */}
            {filtered.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon">💤</div>
                    <div>{filter === 'all' ? 'No claims yet. Triggers fire automatically.' : `No ${filter} claims.`}</div>
                </div>
            ) : (
                <div className="claims-feed">
                    {filtered.map((c, i) => {
                        const cfg = STATUS_CFG[c.status] ?? { emoji: '⏳', color: '#9b93c0', label: c.status };
                        const evEmoji = EVENT_EMOJI[c.event_type] ?? '⚡';
                        return (
                            <div className="claim-card" key={c.id} style={{ '--delay': `${i * 0.05}s` }}>
                                <div className="claim-card-top">
                                    <div className="event-icon">{evEmoji}</div>
                                    <div className="claim-card-info">
                                        <div className="claim-card-type">{c.event_type ?? 'Parametric Event'}</div>
                                        <div className="claim-card-zone">{c.zone_name ?? 'Unknown Zone'} · Sev {c.event_severity ?? '—'}</div>
                                    </div>
                                    <div className="claim-card-amount" style={{ color: cfg.color }}>
                                        +₹{c.payout_amount.toLocaleString('en-IN')}
                                    </div>
                                </div>
                                <div className="claim-card-bot">
                                    <span className="claim-status-pill" style={{ color: cfg.color, borderColor: `${cfg.color}44`, background: `${cfg.color}12` }}>
                                        {cfg.emoji} {cfg.label}
                                    </span>
                                    <span className="claim-ts">
                                        {new Date(c.created_at).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                                    </span>
                                </div>
                                {c.upi_webhook_fired && (
                                    <div className="upi-fired">💸 UPI webhook fired · Txn #{c.id.toString().padStart(4, '0')}</div>
                                )}
                                {c.trust_score && (
                                    <div className="trust-bar-wrap">
                                        <div className="trust-bar-label">Trust Score</div>
                                        <div className="trust-bar">
                                            <div className="trust-fill" style={{ width: `${c.trust_score}%`, background: c.trust_score >= 75 ? '#4ade80' : c.trust_score >= 40 ? '#fbbf24' : '#f87171' }} />
                                        </div>
                                        <span className="trust-val">{Math.round(c.trust_score)}</span>
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
