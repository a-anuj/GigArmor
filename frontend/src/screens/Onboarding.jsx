import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldCheck, MapPin, BarChart3, AlertTriangle, CheckCircle2, ChevronRight, ArrowLeft } from 'lucide-react';
import { getZones, registerWorker, loginWorker } from '../api';
import { useWorker } from '../context/WorkerContext';
import './Onboarding.css';

const STEPS = ['Platform', 'Profile', 'Zone', 'UPI'];

const PLATFORMS = [
    { id: 'zepto',          name: 'Zepto',            color: '#8B5CF6' },
    { id: 'blinkit',        name: 'Blinkit',          color: '#FFCC00' },
    { id: 'swiggy_instamart', name: 'Swiggy Instamart', color: '#FC8019' },
];

export default function Onboarding() {
    const [step, setStep] = useState(0);
    const [zones, setZones] = useState([]);
    const [isLogin, setIsLogin] = useState(false);
    const [loginPhone, setLoginPhone] = useState('');
    const [loginError, setLoginError] = useState('');
    const [loadingLogin, setLoadingLogin] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [form, setForm] = useState({
        platform: '', name: '', phone: '', zone_id: '', upi_id: '',
    });
    const { saveWorker } = useWorker();
    const nav = useNavigate();

    useEffect(() => {
        getZones().then(r => setZones(r.data)).catch(() => { });
    }, []);

    const handleLogin = async () => {
        setLoginError('');
        setLoadingLogin(true);
        try {
            const { data } = await loginWorker(loginPhone);
            saveWorker(data);
            nav('/dashboard');
        } catch (err) {
            setLoginError(err.response?.data?.detail || 'Login failed.');
        } finally {
            setLoadingLogin(false);
        }
    };

    const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

    const next = () => {
        setError('');
        if (step === 0 && !form.platform) return setError('Select your delivery platform');
        if (step === 1) {
            if (!form.name.trim()) return setError('Name is required');
            if (!/^[6-9]\d{9}$/.test(form.phone)) return setError('Enter a valid 10-digit Indian mobile number');
        }
        if (step === 2 && !form.zone_id) return setError('Select your dark store zone');
        if (step < 3) return setStep(s => s + 1);
        // Final step
        if (!form.upi_id.trim()) return setError('UPI ID is required');
        handleSubmit();
    };

    const handleSubmit = async () => {
        setLoading(true);
        setError('');
        try {
            const { data } = await registerWorker({
                name: form.name.trim(),
                phone: form.phone.trim(),
                zone_id: parseInt(form.zone_id),
                upi_id: form.upi_id.trim(),
            });
            saveWorker({ ...data, platform: form.platform });
            nav('/dashboard');
        } catch (e) {
            setError(e.response?.data?.detail || 'Registration failed. Try a different phone number.');
        } finally {
            setLoading(false);
        }
    };

    const selectedZone = zones.find(z => z.id === parseInt(form.zone_id));

    if (isLogin) {
        return (
            <div className="onboard-screen">
                <div className="onboard-header">
                    <div className="brand-logo">
                        <ShieldCheck size={28} color="var(--primary)" strokeWidth={2.5} />
                        <span>GigArmor</span>
                    </div>
                    <h2 className="section-title">Sign In</h2>
                    <p className="brand-sub">Welcome back. Enter your registered number.</p>
                </div>
                <div className="form-section">
                    <div className="field-group">
                        <label>Mobile Number</label>
                        <input
                            className="field-input"
                            type="tel"
                            value={loginPhone}
                            onChange={e => setLoginPhone(e.target.value.replace(/\D/g, ''))}
                            placeholder="9876543210"
                        />
                    </div>
                    {loginError && (
                        <div className="form-error">
                            <AlertTriangle size={14} />
                            {loginError}
                        </div>
                    )}
                    <button className="btn-primary" onClick={handleLogin} disabled={loadingLogin}>
                        {loadingLogin ? <span className="spinner" /> : 'Login Securely'}
                    </button>
                    <button className="btn-ghost" onClick={() => setIsLogin(false)}>
                        No account? Register here
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="onboard-screen">
            {/* Header */}
            <div className="onboard-header">
                <div className="brand-logo">
                    <ShieldCheck size={26} color="var(--primary)" strokeWidth={2.5} />
                    <span>GigArmor</span>
                </div>
                <div className="brand-tagline">Protect Your Income</div>
                <p className="brand-sub">Parametric income insurance built for delivery workers.</p>
            </div>

            {/* Step indicator */}
            <div className="step-dots">
                {STEPS.map((s, i) => (
                    <div key={s} className={`step-dot${i === step ? ' active' : i < step ? ' done' : ''}`}>
                        {i < step ? <CheckCircle2 size={13} strokeWidth={2.5} /> : i + 1}
                        <span className="step-label">{s}</span>
                    </div>
                ))}
                <div className="step-line" style={{ width: `${(step / (STEPS.length - 1)) * 100}%` }} />
            </div>

            {/* Step 0 — Platform */}
            {step === 0 && (
                <div className="form-section fade-up">
                    <h2 className="section-title">Select Your Platform</h2>
                    <p className="section-hint">Your platform determines your zone availability and premium base rate.</p>
                    <div className="platform-grid">
                        {PLATFORMS.map(p => (
                            <button
                                key={p.id}
                                className={`platform-card${form.platform === p.id ? ' selected' : ''}`}
                                style={{ '--platform-color': p.color }}
                                onClick={() => set('platform', p.id)}
                            >
                                <span className="platform-dot" style={{ background: p.color }} />
                                {p.name}
                                {form.platform === p.id && <CheckCircle2 size={14} className="platform-check" />}
                            </button>
                        ))}
                    </div>
                </div>
            )}

            {/* Step 1 — Profile */}
            {step === 1 && (
                <div className="form-section fade-up">
                    <h2 className="section-title">Personal Details</h2>
                    <div className="field-group">
                        <label>Full Name</label>
                        <input
                            className="field-input"
                            placeholder="Arjun Kumar"
                            value={form.name}
                            onChange={e => set('name', e.target.value)}
                        />
                    </div>
                    <div className="field-group">
                        <label>Mobile Number</label>
                        <div className="input-prefix-wrap">
                            <span className="input-prefix">+91</span>
                            <input
                                className="field-input"
                                type="tel"
                                placeholder="9876543210"
                                maxLength={10}
                                value={form.phone}
                                onChange={e => set('phone', e.target.value.replace(/\D/g, ''))}
                            />
                        </div>
                    </div>
                </div>
            )}

            {/* Step 2 — Zone */}
            {step === 2 && (
                <div className="form-section fade-up">
                    <h2 className="section-title">Select Your Dark Store Zone</h2>
                    <p className="section-hint">Coverage is hyperlocal to your zone's 2.5 km radius.</p>
                    <div className="zone-grid">
                        {zones.map(z => {
                            const risk = z.base_risk_multiplier <= 1.0 ? 'LOW' : z.base_risk_multiplier <= 1.2 ? 'MED' : 'HIGH';
                            const riskColor = { LOW: '#22c55e', MED: '#f59e0b', HIGH: '#ef4444' }[risk];
                            return (
                                <div
                                    key={z.id}
                                    className={`zone-card${form.zone_id === String(z.id) ? ' selected' : ''}`}
                                    onClick={() => set('zone_id', String(z.id))}
                                >
                                    <div className="zone-name">{z.name}</div>
                                    <div className="zone-meta">
                                        <span className="zone-pin">
                                            <MapPin size={10} /> {z.pincode}
                                        </span>
                                        <span className="zone-risk" style={{ color: riskColor }}>
                                            <span className="risk-dot-sm" style={{ background: riskColor }} />
                                            {risk}
                                        </span>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                    {selectedZone && (
                        <div className="zone-premium-preview">
                            <BarChart3 size={13} />
                            Est. risk multiplier: <strong>{selectedZone.base_risk_multiplier}×</strong>
                        </div>
                    )}
                </div>
            )}

            {/* Step 3 — UPI */}
            {step === 3 && (
                <div className="form-section fade-up">
                    <h2 className="section-title">UPI Payment Setup</h2>
                    <p className="section-hint">Payouts arrive in under 60 seconds, automatically.</p>
                    <div className="field-group">
                        <label>UPI ID</label>
                        <input
                            className="field-input"
                            placeholder="arjun@upi"
                            value={form.upi_id}
                            onChange={e => set('upi_id', e.target.value)}
                        />
                    </div>
                    <div className="agreement-box">
                        <CheckCircle2 size={16} className="check-icon" />
                        I agree to the <strong>Service Armor Agreement</strong> and consent to automated earnings verification.
                    </div>
                </div>
            )}

            {/* Error */}
            {error && (
                <div className="form-error">
                    <AlertTriangle size={14} />
                    {error}
                </div>
            )}

            {/* CTA */}
            <div className="onboard-cta">
                {step > 0 && (
                    <button className="btn-ghost" onClick={() => { setError(''); setStep(s => s - 1); }}>
                        <ArrowLeft size={16} /> Back
                    </button>
                )}
                <button className="btn-primary" onClick={next} disabled={loading}>
                    {loading
                        ? <span className="spinner" />
                        : step < 3
                            ? <><span>Continue</span><ChevronRight size={16} /></>
                            : <><ShieldCheck size={16} /><span>Activate Shield</span></>
                    }
                </button>
            </div>

            <div className="onboard-footer">
                {!isLogin && (
                    <button className="footer-login-link" onClick={() => setIsLogin(true)}>
                        Already registered? Sign In
                    </button>
                )}
                <div>Powered by GigArmor · Guidewire DEVTrails 2026</div>
            </div>
        </div>
    );
}
