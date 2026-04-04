import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getZones, registerWorker, loginWorker } from '../api';
import { useWorker } from '../context/WorkerContext';
import './Onboarding.css';

const STEPS = ['Profile', 'Zone', 'UPI'];

export default function Onboarding() {
    const [step, setStep] = useState(0);
    const [zones, setZones] = useState([]);
    const [isLogin, setIsLogin] = useState(false);
    const [loginPhone, setLoginPhone] = useState('');
    const [loginError, setLoginError] = useState('');
    const [loadingLogin, setLoadingLogin] = useState(false);
    const { saveWorker } = useWorker();
    const nav = useNavigate();

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

    if (isLogin) {
        return (
            <div className="onboard-screen">
                <div className="onboard-header">
                    <div className="brand-logo">🛡️ GigArmor</div>
                    <h2 className="section-title">Login</h2>
                    <p className="brand-sub">Welcome back securely</p>
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
                    {loginError && <div className="form-error">⚠ {loginError}</div>}
                    <button className="btn-primary" onClick={handleLogin} disabled={loadingLogin}>
                        {loadingLogin ? 'Verifying...' : 'Login securely'}
                    </button>
                    <button className="btn-ghost" onClick={() => setIsLogin(false)}>
                        Don't have an account? Register
                    </button>
                </div>
            </div>
        );
    }

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [form, setForm] = useState({
        name: '', phone: '', zone_id: '', upi_id: '',
    });

    useEffect(() => {
        getZones().then(r => setZones(r.data)).catch(() => { });
    }, []);

    const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

    const next = () => {
        setError('');
        if (step === 0) {
            if (!form.name.trim()) return setError('Name is required');
            if (!/^[6-9]\d{9}$/.test(form.phone)) return setError('Enter a valid 10-digit Indian mobile number');
        }
        if (step === 1 && !form.zone_id) return setError('Select your dark store zone');
        if (step < 2) return setStep(s => s + 1);
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
            saveWorker(data);
            nav('/dashboard');
        } catch (e) {
            setError(e.response?.data?.detail || 'Registration failed. Try a different phone number.');
        } finally {
            setLoading(false);
        }
    };

    const selectedZone = zones.find(z => z.id === parseInt(form.zone_id));

    return (
        <div className="onboard-screen">
            {/* Header */}
            <div className="onboard-header">
                <div className="brand-logo">🛡️ GigArmor</div>
                <div className="brand-tagline">Protect Your Income</div>
                <p className="brand-sub">Join the fleet. Deploy your professional shield and start earning with security.</p>
            </div>

            {/* Step indicator */}
            <div className="step-dots">
                {STEPS.map((s, i) => (
                    <div key={s} className={`step-dot${i === step ? ' active' : i < step ? ' done' : ''}`}>
                        {i < step ? '✓' : i + 1}
                        <span className="step-label">{s}</span>
                    </div>
                ))}
                <div className="step-line" style={{ width: `${(step / (STEPS.length - 1)) * 100}%` }} />
            </div>

            {/* Step 0 — Profile */}
            {step === 0 && (
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

            {/* Step 1 — Zone */}
            {step === 1 && (
                <div className="form-section fade-up">
                    <h2 className="section-title">Select Your Dark Store Zone</h2>
                    <p className="section-hint">Coverage is hyperlocal to your zone's 2.5 km radius.</p>
                    <div className="zone-grid">
                        {zones.map(z => {
                            const risk = z.base_risk_multiplier <= 1.0 ? 'LOW' : z.base_risk_multiplier <= 1.2 ? 'MED' : 'HIGH';
                            const riskColor = { LOW: '#4ade80', MED: '#fbbf24', HIGH: '#f87171' }[risk];
                            return (
                                <div
                                    key={z.id}
                                    className={`zone-card${form.zone_id === String(z.id) ? ' selected' : ''}`}
                                    onClick={() => set('zone_id', String(z.id))}
                                >
                                    <div className="zone-name">{z.name}</div>
                                    <div className="zone-meta">
                                        <span className="zone-pin">📍 {z.pincode}</span>
                                        <span className="zone-risk" style={{ color: riskColor }}>● {risk}</span>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                    {selectedZone && (
                        <div className="zone-premium-preview">
                            📊 Est. premium multiplier: <strong>{selectedZone.base_risk_multiplier}×</strong>
                        </div>
                    )}
                </div>
            )}

            {/* Step 2 — UPI */}
            {step === 2 && (
                <div className="form-section fade-up">
                    <h2 className="section-title">UPI Payment Setup</h2>
                    <p className="section-hint">Used for daily instant earnings settlement. Payouts arrive in &lt;60 seconds.</p>
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
                        <span className="check-icon">✓</span>
                        I agree to the <strong>Service Armor Agreement</strong> and consent to automated earnings verification.
                    </div>
                </div>
            )}

            {/* Error */}
            {error && <div className="form-error">⚠ {error}</div>}

            {/* CTA */}
            <div className="onboard-cta">
                {step > 0 && (
                    <button className="btn-ghost" onClick={() => { setError(''); setStep(s => s - 1); }}>
                        ← Back
                    </button>
                )}
                <button className="btn-primary" onClick={next} disabled={loading}>
                    {loading ? <span className="spinner" /> : step < 2 ? 'Continue →' : 'Activate Shield 🛡️'}
                </button>
            </div>

            <div className="onboard-footer">Powered by GigArmor Infrastructure · Guidewire DEVTrails 2026</div>
        </div>
    );
}
