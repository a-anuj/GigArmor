import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    ShieldCheck, LogOut, Award, Zap, BarChart3,
    CircleCheck, Clock, XCircle, MoonStar, Banknote,
    Droplets, Thermometer, Wind, MapPin, CloudRain
} from 'lucide-react';
import { getWorker, getWorkerClaims, enrollPolicy, simulateTrigger, fetchWeather } from '../api';
import { useWorker } from '../context/WorkerContext';
import { useGeolocation } from '../hooks/useGeolocation';
import { getNearestZoneName } from '../utils/zoneMapping';
import { useTranslation } from 'react-i18next';
import './Dashboard.css';

const RISK_COLORS = { LOW: '#22c55e', MEDIUM: '#f59e0b', HIGH: '#ef4444' };

function riskFromMultiplier(m) {
    if (!m) return 'UNKNOWN';
    if (m <= 1.0) return 'LOW';
    if (m <= 1.3) return 'MEDIUM';
    return 'HIGH';
}

function weatherRisk(weather) {
    if (!weather) return 'LOW';
    if (weather.rain_mm >= 5 || weather.aqi > 150) return 'HIGH';
    if (weather.rain_mm >= 2 || weather.aqi > 100) return 'MEDIUM';
    return 'LOW';
}

function StatusBadge({ status }) {
    const cfg = {
        'Auto-Approved': { Icon: CircleCheck, color: '#22c55e', label: 'Paid Out' },
        'Soft-Hold':     { Icon: Clock,       color: '#f59e0b', label: 'Processing' },
        'Blocked':       { Icon: XCircle,     color: '#ef4444', label: 'Blocked' },
    }[status] ?? { Icon: Clock, color: '#808080', label: status };
    const { Icon } = cfg;
    return (
        <span className="status-badge" style={{ color: cfg.color, borderColor: `${cfg.color}33`, background: `${cfg.color}15` }}>
            <Icon size={10} strokeWidth={2.5} />
            {cfg.label}
        </span>
    );
}

export default function Dashboard() {
    const { t } = useTranslation();
    const { worker, clearWorker } = useWorker();
    const nav = useNavigate();
    const { coords } = useGeolocation();

    const [profile, setProfile] = useState(null);
    const [claims, setClaims] = useState([]);
    const [weather, setWeather] = useState(null);
    const [enrolling, setEnrolling] = useState(false);
    const [enrollMsg, setEnrollMsg] = useState('');
    const [enrollSuccess, setEnrollSuccess] = useState(false);
    const [loading, setLoading] = useState(true);

    // Fetch worker data
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

    // Fetch weather once we have coords
    useEffect(() => {
        if (!coords) return;
        fetchWeather(coords.lat, coords.lon).then(setWeather);
    }, [coords]);

    const handleEnroll = async () => {
        setEnrolling(true);
        setEnrollMsg('');
        try {
            await enrollPolicy(worker.id);
            setEnrollMsg('Policy activated — Coverage: ₹1,200');
            setEnrollSuccess(true);
            setTimeout(() => setEnrollMsg(''), 4000);
        } catch (e) {
            setEnrollMsg(e.response?.data?.detail || 'Enrollment error');
            setEnrollSuccess(false);
        } finally {
            setEnrolling(false);
        }
    };

    const handleSimulateDemo = async () => {
        setEnrolling(true);
        try {
            const res = await simulateTrigger({ zone_id: profile?.zone_id ?? 1, event_type: 'Rain', severity: 'High' });
            if (res.data.claims_generated === 0) {
                setEnrollMsg('Trigger fired, but no active policy. Please Enroll first!');
                setEnrollSuccess(false);
            } else {
                setEnrollMsg('Trigger fired — claim processing...');
                setEnrollSuccess(true);
            }
            const c = await getWorkerClaims(worker.id);
            setClaims(c.data.claims || []);
            setTimeout(() => setEnrollMsg(''), 4000);
        } catch (e) {
            setEnrollMsg('Demo trigger failed');
            setEnrollSuccess(false);
        } finally {
            setEnrolling(false);
        }
    };

    const risk = riskFromMultiplier(profile?.zone?.base_risk_multiplier);
    const liveRisk = weatherRisk(weather);
    const dynamicCoverage = profile?.zone?.base_risk_multiplier
        ? Math.round(profile.zone.base_risk_multiplier * 1000)
        : 1200;

    const activeZoneName = profile?.zone?.name ?? getNearestZoneName(coords);

    if (!worker) return null;
    if (loading) return (
        <div className="screen-loading">
            <div className="pulse-ring" />
            <span>{t('loading')}</span>
        </div>
    );

    const totalPaid = claims
        .filter(c => c.status === 'Auto-Approved')
        .reduce((s, c) => s + c.payout_amount, 0);

    return (
        <div className="dashboard-screen">
            {/* Top bar */}
            <div className="dash-topbar">
                <div>
                    <div className="dash-welcome">{t('welcome_back')}</div>
                    <div className="dash-name">{worker.name.split(' ')[0]}</div>
                </div>
                <button className="logout-btn" onClick={() => { clearWorker(); nav('/onboarding'); }}>
                    <LogOut size={16} />
                </button>
            </div>

            {/* Active Zone + Live Risk pill */}
            <div className="zone-banner">
                <div className="zone-banner-left">
                    <MapPin size={13} color="var(--primary)" />
                    <span className="zone-banner-name">{activeZoneName}</span>
                </div>
                <div className="zone-risk-pill" style={{ color: RISK_COLORS[liveRisk], borderColor: `${RISK_COLORS[liveRisk]}44`, background: `${RISK_COLORS[liveRisk]}12` }}>
                    <span className="risk-dot" style={{ background: RISK_COLORS[liveRisk] }} />
                    {liveRisk} RISK
                </div>
            </div>

            {/* Live Conditions card */}
            {weather && (
                <div className="weather-card">
                    <div className="weather-card-title">
                        <CloudRain size={14} color="var(--primary)" />
                        {t('live_conditions')}
                        <span className="live-dot" />
                        <span className="live-label">LIVE</span>
                    </div>
                    <div className="weather-metrics">
                        <div className="weather-metric">
                            <Droplets size={18} color="var(--info)" />
                            <div className="metric-val">{weather.rain_mm} mm/hr</div>
                            <div className="metric-key">Rainfall</div>
                        </div>
                        <div className="weather-metric">
                            <Thermometer size={18} color="var(--warning)" />
                            <div className="metric-val">{weather.temp.toFixed(1)}°C</div>
                            <div className="metric-key">Temp</div>
                        </div>
                        <div className="weather-metric">
                            <Wind size={18} color={weather.aqi > 150 ? 'var(--error)' : weather.aqi > 100 ? 'var(--warning)' : 'var(--success)'} />
                            <div className="metric-val">{weather.aqi}</div>
                            <div className="metric-key">AQI</div>
                        </div>
                    </div>
                </div>
            )}

            {/* Active policy card */}
            <div className="policy-card">
                <div className="policy-card-header">
                    <span className="policy-label">{t('active_policy')}</span>
                    <ShieldCheck size={22} color="var(--primary)" strokeWidth={2} className="shield-glow-icon" />
                </div>
                <div className="policy-coverage-row">
                    <div>
                        <div className="coverage-label">Coverage</div>
                        <div className="coverage-amount">₹{dynamicCoverage.toLocaleString('en-IN')}</div>
                    </div>
                    <div className="risk-pill" style={{ color: RISK_COLORS[risk], borderColor: `${RISK_COLORS[risk]}44` }}>
                        <span className="risk-dot" style={{ background: RISK_COLORS[risk] }} />
                        {risk} RISK
                    </div>
                </div>
                <div className="shield-credits-tag">
                    <Award size={13} />
                    Shield Credits: Active (20% Discount)
                </div>
                <div className="policy-actions">
                    <button className="action-btn" onClick={() => nav('/quote')}>
                        <BarChart3 size={14} />
                        {t('get_quote')}
                    </button>
                    <button className="action-btn primary" onClick={handleEnroll} disabled={enrolling}>
                        {enrolling ? <span className="spinner" /> : t('enroll_week')}
                    </button>
                </div>
                {enrollMsg && (
                    <div className={`enroll-msg ${enrollSuccess ? 'success' : 'error'}`}>
                        {enrollMsg}
                    </div>
                )}
            </div>

            {/* Wallet */}
            <div className="wallet-card">
                <div className="wallet-header">
                    <span className="wallet-title">HustleHalt Wallet</span>
                    <span className={`trust-badge ${worker.cold_start_active ? 'cold' : 'verified'}`}>
                        {worker.cold_start_active ? 'Cold Start' : 'Verified'}
                    </span>
                </div>
                <div className="wallet-balance">
                    ₹{totalPaid.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
                <div className="wallet-subtext">Total Auto-Claim Disbursements ({claims.length} claims)</div>
                <div className="wallet-actions">
                    <button className="wallet-btn withdraw-btn">
                        <Banknote size={14} />
                        Withdraw to UPI
                    </button>
                    <button className="wallet-btn demo-trigger-btn" onClick={handleSimulateDemo} disabled={enrolling}>
                        {enrolling ? <span className="spinner dark" /> : (
                            <><Zap size={14} /> Mock Rain Event</>
                        )}
                    </button>
                </div>
            </div>

            {/* Recent payouts */}
            <div className="section-head">
                <span>{t('recent_payouts')}</span>
                <span className="zero-touch-tag">
                    <Zap size={10} />
                    Zero-Touch
                </span>
            </div>

            {claims.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon"><MoonStar size={24} /></div>
                    <div>No payouts yet. Stay active — triggers fire automatically.</div>
                </div>
            ) : (
                <div className="claims-list">
                    {claims.slice(0, 5).map(c => (
                        <div key={c.id} className="claim-row">
                            <div className="claim-left">
                                <div className="claim-type">{c.event_type ?? 'Parametric Event'}{c.zone_name ? ` — ${c.zone_name}` : ''}</div>
                                <div className="claim-date">{new Date(c.created_at).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}</div>
                            </div>
                            <div className="claim-right">
                                <div className="claim-amt" style={{ color: c.status === 'Auto-Approved' ? '#22c55e' : undefined }}>
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
                <button className="quick-btn" onClick={() => nav('/quote')}>
                    <BarChart3 size={14} /> {t('nav.quote')}
                </button>
                <button className="quick-btn" onClick={() => nav('/claims')}>
                    <Zap size={14} /> {t('nav.claims')}
                </button>
            </div>
        </div>
    );
}
