import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
const OWM_KEY  = import.meta.env.VITE_OPENWEATHER_KEY || '';

const api = axios.create({
    baseURL: BASE_URL,
    headers: { 'Content-Type': 'application/json' },
});

// ── Workers ─────────────────────────────────────────────────────────────
export const getZones = () => api.get('/api/v1/zones');
export const registerWorker = (data) => api.post('/api/v1/workers/register', data);
export const loginWorker = (phone) => api.post('/api/v1/workers/login', { phone });
export const getWorker = (id) => api.get(`/api/v1/workers/${id}`);
export const listWorkers = () => api.get('/api/v1/workers');

// ── Policies ─────────────────────────────────────────────────────────────
export const getPremiumQuote = (workerId) => api.get(`/api/v1/policies/quote/${workerId}`);
export const enrollPolicy = (workerId) => api.post('/api/v1/policies/enroll', { worker_id: workerId });
export const getWorkerPolicies = (workerId) => api.get(`/api/v1/policies/worker/${workerId}`);

// ── Claims ──────────────────────────────────────────────────────────────
export const getWorkerClaims = (workerId) => api.get(`/api/v1/claims/worker/${workerId}`);
export const getClaim = (claimId) => api.get(`/api/v1/claims/${claimId}`);

// ── Admin ───────────────────────────────────────────────────────────────
export const getPlatformStats = () => api.get('/api/v1/admin/stats');
export const getTriggers = () => api.get('/api/v1/admin/triggers');
export const simulateTrigger = (data) => api.post('/api/v1/admin/simulate-trigger', data);

// ── Weather ─────────────────────────────────────────────────────────────
const MOCK_WEATHER = {
    temp: 29.4,
    feels_like: 33.1,
    description: 'Partly cloudy',
    rain_mm: 2.1,          // mm/hr — triggers parametric at ≥3mm
    aqi: 87,               // mock AQI (moderate)
    humidity: 72,
    wind_kph: 14,
    icon: 'cloudy',
};

export async function fetchWeather(lat, lon) {
    if (!OWM_KEY) {
        // Return realistic Bangalore mock — no API key needed
        return { ...MOCK_WEATHER };
    }
    try {
        const { data } = await axios.get(
            `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OWM_KEY}&units=metric`
        );
        return {
            temp:        data.main.temp,
            feels_like:  data.main.feels_like,
            description: data.weather?.[0]?.description ?? '—',
            rain_mm:     data.rain?.['1h'] ?? 0,
            aqi:         MOCK_WEATHER.aqi,     // OWM free tier doesn't include AQI in this call
            humidity:    data.main.humidity,
            wind_kph:    Math.round((data.wind?.speed ?? 0) * 3.6),
            icon:        data.weather?.[0]?.icon ?? 'cloudy',
        };
    } catch {
        return { ...MOCK_WEATHER };
    }
}

export default api;

