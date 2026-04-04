import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    CheckCircle2, Clock, AlertTriangle, CloudRain, Wind,
    Radio, Ban, Thermometer, Zap, MoonStar, Banknote
} from 'lucide-react';
import { getWorkerClaims } from '../api';
import { useWorker } from '../context/WorkerContext';
import './Claims.css';

const STATUS_CFG = {
    'Auto-Approved': {
        Icon: CheckCircle2,
        color: '#22c55e',
        bg: 'rgba(34,197,94,0.08)',
        border: 'rgba(34,197,94,0.2)',
        label: 'Auto-Approved',
        sublabel: 'Paid Out',
    },
    'Soft-Hold': {
        Icon: Clock,
        color: '#f59e0b',
        bg: 'rgba(245,158,11,0.08)',
        border: 'rgba(245,158,11,0.2)',
        label: 'Processing',
        sublabel: 'Claim is processing. Update in 4 hours.',
    },
    'Blocked': {
        Icon: AlertTriangle,
        color: '#808080',
        bg: 'rgba(128,128,128,0.08)',
        border: 'rgba(128,128,128,0.2)',
        label: 'Blocked',
        sublabel: 'Appeal window open · 72 hours',
    },
};

const EVENT_ICONS = {
    Rain:    CloudRain,
    AQI:     Wind,
    Outage:  Radio,
    Social:  Ban,
    Heat:    Thermometer,
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
    if (loading) return (
        <div className="screen-loading">
            <div className="pulse-ring" />
            <span>Loading claims…</span>
        </div>
    );

    const claims = data?.claims ?? [];
    const filtered = filter === 'all' ? claims : claims.filter(c => c.status === filter);

    return (
        <div className="claims-screen">
            <div className="claims-topbar">
                <div className="claims-title">Claims Feed</div>
                <div className="zero-touch-badge">
                    <Zap size={10} />
                    Zero-Touch
                </div>
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
                        {f === 'all' ? 'All' : f}
                    </button>
                ))}
            </div>

            {/* Claims list */}
            {filtered.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon">
                        <MoonStar size={24} />
                    </div>
                    <div>{filter === 'all' ? 'No claims yet. Triggers fire automatically.' : `No ${filter} claims.`}</div>
                </div>
            ) : (
                <div className="claims-feed">
                    {filtered.map((c, i) => {
                        const cfg = STATUS_CFG[c.status] ?? {
                            Icon: Clock, color: '#808080', bg: 'rgba(128,128,128,0.08)', border: 'rgba(128,128,128,0.2)',
                            label: c.status, sublabel: '',
                        };
                        const EventIcon = EVENT_ICONS[c.event_type] ?? Zap;
                        const { Icon } = cfg;
                        return (
                            <div
                                className="claim-card"
                                key={c.id}
                                style={{
                                    '--delay': `${i * 0.05}s`,
                                    borderColor: cfg.border,
                                    background: cfg.bg,
                                }}
                            >
                                {/* Status banner */}
                                <div className="claim-status-banner" style={{ color: cfg.color }}>
                                    <Icon size={14} strokeWidth={2.5} />
                                    <span className="claim-status-label">{cfg.label}</span>
                                    {cfg.sublabel && (
                                        <span className="claim-status-sublabel">{cfg.sublabel}</span>
                                    )}
                                </div>

                                <div className="claim-card-top">
                                    <div className="event-icon-wrap" style={{ color: cfg.color }}>
                                        <EventIcon size={20} strokeWidth={1.8} />
                                    </div>
                                    <div className="claim-card-info">
                                        <div className="claim-card-type">{c.event_type ?? 'Parametric Event'}</div>
                                        <div className="claim-card-zone">{c.zone_name ?? 'Unknown Zone'} · Sev {c.event_severity ?? '—'}</div>
                                    </div>
                                    <div className="claim-card-amount" style={{ color: cfg.color }}>
                                        +₹{c.payout_amount.toLocaleString('en-IN')}
                                    </div>
                                </div>

                                <div className="claim-card-bot">
                                    <span className="claim-ts">
                                        {new Date(c.created_at).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                                    </span>
                                    {/* Blocked — appeal note */}
                                    {c.status === 'Blocked' && (
                                        <span className="appeal-note">File appeal via Help Center</span>
                                    )}
                                    {/* Auto-Approved — UPI fired */}
                                    {c.upi_webhook_fired && (
                                        <span className="upi-fired">
                                            <Banknote size={11} />
                                            UPI Txn #{c.id.toString().padStart(4, '0')}
                                        </span>
                                    )}
                                </div>

                                {c.trust_score && (
                                    <div className="trust-bar-wrap">
                                        <div className="trust-bar-label">Trust Score</div>
                                        <div className="trust-bar">
                                            <div
                                                className="trust-fill"
                                                style={{
                                                    width: `${c.trust_score}%`,
                                                    background: c.trust_score >= 75 ? '#22c55e' : c.trust_score >= 40 ? '#f59e0b' : '#ef4444',
                                                }}
                                            />
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
