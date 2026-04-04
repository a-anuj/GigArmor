import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    ShieldCheck, ArrowLeft, Package, Zap, CalendarDays,
    Award, Radio, BadgeInfo, Tag
} from 'lucide-react';
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
    const [msgSuccess, setMsgSuccess] = useState(false);
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
            setMsg('Policy enrolled — you are covered for this week.');
            setMsgSuccess(true);
        } catch (e) {
            setMsg(e.response?.data?.detail || 'Enrollment failed.');
            setMsgSuccess(false);
        } finally {
            setEnrolling(false);
        }
    };

    if (!worker) return null;
    if (loading) return (
        <div className="screen-loading">
            <div className="pulse-ring" />
            <span>Loading quote…</span>
        </div>
    );

    return (
        <div className="quote-screen">
            {/* Header */}
            <div className="quote-header">
                <button className="back-btn" onClick={() => nav('/dashboard')}>
                    <ArrowLeft size={18} />
                </button>
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
                        <div className="premium-floor-ceil">
                            <Tag size={12} />
                            Floor ₹19 · Ceiling ₹99 /week
                        </div>
                        <div className="premium-amount">₹{quote?.premium ?? '—'}</div>
                        <div className="premium-period">per week</div>
                        <div className="premium-tags">
                            {quote?.shield_credits_applied && (
                                <span className="premium-tag discount">
                                    <Award size={12} />
                                    Shield Discount · Tier 3
                                </span>
                            )}
                            {quote?.cold_start_active && (
                                <span className="premium-tag warning">
                                    <BadgeInfo size={12} />
                                    Cold-Start Period
                                </span>
                            )}
                        </div>
                    </div>

                    {/* AI Breakdown */}
                    <div className="multipliers-card">
                        <div className="mult-card-title">AI Breakdown</div>
                        <div className="mult-card-formula">
                            Base × Weather × Social × Shift Ratio
                        </div>
                        <div className="mult-row">
                            <span className="mult-label">Base Rate</span>
                            <span className="mult-val">₹{quote?.r_base ?? 5}</span>
                        </div>
                        <div className="mult-row">
                            <span className="mult-label">Weather Alert</span>
                            <span className="mult-val highlight">{quote?.m_weather ?? '—'}×</span>
                        </div>
                        <div className="mult-row">
                            <span className="mult-label">Social Events</span>
                            <span className="mult-val">{quote?.m_social ?? '—'}×</span>
                        </div>
                        <div className="mult-row">
                            <span className="mult-label">Shift Ratio</span>
                            <span className="mult-val">{quote?.h_expected ?? '1.0'}×</span>
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
                        {[
                            { Icon: Package, label: 'Coverage Amount', value: `₹${quote?.coverage_amount ?? 1200}` },
                            { Icon: Zap, label: 'Payout Time', value: '≤ 60 seconds' },
                            { Icon: CalendarDays, label: 'Period', value: '7 days' },
                            { Icon: Award, label: 'Quiet Weeks', value: `${quote?.consecutive_quiet_weeks ?? 0} week(s)` },
                        ].map(({ Icon, label, value }) => (
                            <div key={label} className="cov-row">
                                <span className="cov-label">
                                    <Icon size={14} />
                                    {label}
                                </span>
                                <strong>{value}</strong>
                            </div>
                        ))}
                    </div>

                    {/* Live feed label */}
                    <div className="risk-map-label">
                        <Radio size={13} />
                        Dynamic Risk Map · Live Feed · Updated now
                    </div>

                    {/* Enroll CTA */}
                    {msg ? (
                        <div className={`enroll-result ${msgSuccess ? 'success' : 'error'}`}>{msg}</div>
                    ) : (
                        <button className="enroll-cta" onClick={handleEnroll} disabled={enrolling}>
                            {enrolling
                                ? <span className="spinner" />
                                : <><ShieldCheck size={18} /> Activate This Week's Coverage</>
                            }
                        </button>
                    )}
                </>
            )}
        </div>
    );
}
