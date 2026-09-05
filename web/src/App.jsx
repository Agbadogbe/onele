import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ToastProvider } from './components/Toast';
import { RealtimeProvider } from './context/RealtimeContext';
import Layout from './components/Layout';
import Mark from './components/Mark';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Demandes from './pages/Demandes';
import Utilisateurs from './pages/Utilisateurs';
import Materiel from './pages/Materiel';
import Historique from './pages/Historique';

function RequireAuth({ children }) {
  const { user, loading } = useAuth();
  if (loading) {
    return (
      <div className="boot aurora">
        <Mark size={54} />
        <span className="eyebrow">Chargement de votre espace…</span>
      </div>
    );
  }
  if (!user) return <Navigate to="/login" replace />;
  return children;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/"
        element={
          <RequireAuth>
            <Layout />
          </RequireAuth>
        }
      >
        <Route index element={<Dashboard />} />
        <Route path="demandes" element={<Demandes />} />
        <Route path="utilisateurs" element={<Utilisateurs />} />
        <Route path="materiel" element={<Materiel />} />
        <Route path="historique" element={<Historique />} />
      </Route>
    </Routes>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ToastProvider>
          <RealtimeProvider>
            <AppRoutes />
          </RealtimeProvider>
        </ToastProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}
