import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

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

export default api;
