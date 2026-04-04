import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import AppLayout from './components/AppLayout';
import Onboarding from './screens/Onboarding';
import Dashboard from './screens/Dashboard';
import PremiumQuote from './screens/PremiumQuote';
import Claims from './screens/Claims';
import AdminDashboard from './screens/AdminDashboard';
import { WorkerProvider } from './context/WorkerContext';

export default function App() {
  return (
    <BrowserRouter>
      <WorkerProvider>
        <Routes>
          {/* Full-page admin — no phone frame */}
          <Route path="/admin" element={<AdminDashboard />} />
          {/* Worker app — displayed in a phone frame */}
          <Route element={<AppLayout />}>
            <Route index element={<Navigate to="/onboarding" replace />} />
            <Route path="/onboarding" element={<Onboarding />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/quote" element={<PremiumQuote />} />
            <Route path="/claims" element={<Claims />} />
          </Route>
        </Routes>
      </WorkerProvider>
    </BrowserRouter>
  );
}
