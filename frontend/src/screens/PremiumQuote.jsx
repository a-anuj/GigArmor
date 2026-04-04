import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getPremiumQuote, enrollPolicy } from '../api';
import { useWorker } from '../context/WorkerContext';
import './PremiumQuote.css';

export default function PremiumQuote() {
    const { worker } = useWorker();
    const nav = useNavigate();
    const [quote, setQuote] = useState(null);
    const [loading, setLoading] = useState(true);
    const [enrolling, setEnrolling] = useState(false);
    const [msg, setMsg] = useState('');
    const [error, setError] = useState('');

    useEffect(() => {
        if (!worker) { nav('/onboarding'); return; }
        getPremiumQuote(worker.id)
            .then(r => setQuote(r.data))
            .catch(() => setError('Could not load quote. Is the backend running?'))
            .finally(() => setLoading(false));
    }, [worker]);

    const handleEnroll = async () => {
        setEnrolling(true);
        setMsg('');
        try {
            await enrollPolicy(worker.id);
            setMsg('✅ Policy enrolled! You are covered for this week.');
        } catch (e) {
            setMsg(e.response?.data?.detail || 'Enrollment failed.');
        } finally {
            setEnrolling(false);
        }
    };

    if (!worker) return null;
    if (loading) return <div className="screen-loading"><div className="pulse-ring" /><span>Loading quote…</span></div>;

    return (
        <div className="quote-screen">
            {/* Header */}
            <div className="quote-header">
                <button className="back-btn" onClick={() => nav('/dashboard')}>←</button>
                <div>
                    <div className="quote-title">Premium for Next Week</div>
                    <div className="quote-sub">{quote?.zone_name}</div>
                </div>
            </div>

            {error ? (
                <div className="error-card">{error}</div>
            ) : (
                <>
                    {/* Big premium number */}
                    <div className="premium-hero">
                        <div className="premium-amount">₹{quote?.premium ?? '—'}</div>
                        {quote?.shield_credits_applied && (
                            <div className="shield-tag">🛡️ Shield Discount Applied · Loyalty Tier 3</div>
                        )}
                        {quote?.cold_start_active && (
                            <div className="coldstart-tag">🆕 Cold-Start Period (1.2× multiplier)</div>
                        )}
                    </div>

                    {/* Multipliers breakdown */}
                    <div className="multipliers-card">
                        <div className="mult-card-title">Risk Multipliers</div>
                        <div className="mult-row">
                            <span className="mult-label">Base Risk</span>
                            <span className="mult-val">1.0×</span>
                        </div>
                        <div className="mult-row">
                            <span className="mult-label">Weather Alert</span>
                            <span className="mult-val highlight">{quote?.m_weather ?? '—'}×</span>
                        </div>
                        <div className="mult-row">
                            <span className="mult-label">Social Events</span>
                            <span className="mult-val">{quote?.m_social ?? '—'}×</span>
                        </div>
                        {quote?.cold_start_active && (
                            <div className="mult-row">
                                <span className="mult-label">Cold-Start</span>
                                <span className="mult-val warning">1.2×</span>
                            </div>
                        )}
                        {quote?.shield_credits_applied && (
                            <div className="mult-row discount">
                                <span className="mult-label">Shield Credits</span>
                                <span className="mult-val success">−₹{Math.round(quote?.discount_amount ?? 0)}</span>
                            </div>
                        )}
                        <div className="mult-divider" />
                        <div className="mult-row total">
                            <span className="mult-label">Weekly Premium</span>
                            <span className="mult-val">₹{quote?.premium}</span>
                        </div>
                    </div>

                    {/* Coverage info */}
                    <div className="coverage-info-card">
                        <div className="cov-row">
                            <span>📦 Coverage Amount</span>
                            <strong>₹{quote?.coverage_amount ?? 1200}</strong>
                        </div>
                        <div className="cov-row">
                            <span>⚡ Payout Time</span>
                            <strong>≤ 60 seconds</strong>
                        </div>
                        <div className="cov-row">
                            <span>📅 Period</span>
                            <strong>7 days</strong>
                        </div>
                        <div className="cov-row">
                            <span>🏆 Quiet Weeks</span>
                            <strong>{quote?.consecutive_quiet_weeks ?? 0} week(s)</strong>
                        </div>
                    </div>

                    {/* Dynamic Risk Map label */}
                    <div className="risk-map-label">
                        📡 Dynamic Risk Map · Live Feed · Updated now
                    </div>

                    {/* Enroll CTA */}
                    {msg ? (
                        <div className={`enroll-result ${msg.startsWith('✅') ? 'success' : 'error'}`}>{msg}</div>
                    ) : (
                        <button className="enroll-cta" onClick={handleEnroll} disabled={enrolling}>
                            {enrolling ? <span className="spinner" /> : "🛡️ Activate This Week's Coverage"}
                        </button>
                    )}
                </>
            )}
        </div>
    );
}
