import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { IconAlert, IconCheck } from '../components/Icons';
import Mark from '../components/Mark';

const ARGUMENTS = [
  'Validez congés, permissions et matériel au même endroit',
  'Chaque décision est tracée et notifiée à l’employé',
  'Vos équipes suivent leurs demandes depuis le mobile',
];

export default function Login() {
  const { user, login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  if (user) return <Navigate to="/" replace />;

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login(email, password);
    } catch (err) {
      setError(err.message ?? 'Connexion impossible.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login">
      <aside className="login-aside aurora">
        <div className="login-mark">
          <Mark size={38} />
          Onélé
        </div>

        <div>
          <h1>
            Les démarches RH, <em>sans la paperasse.</em>
          </h1>
          <p className="lede">
            L’espace d’administration qui centralise les demandes de congés,
            de permissions et de matériel de toute votre organisation.
          </p>
          <ul className="login-points">
            {ARGUMENTS.map((texte) => (
              <li key={texte}>
                <span className="tick">
                  <IconCheck size={13} />
                </span>
                {texte}
              </li>
            ))}
          </ul>
        </div>

        <div className="login-foot">Réservé aux profils RH &amp; administrateurs</div>
      </aside>

      <main className="login-main">
        <form className="login-form" onSubmit={handleSubmit}>
          <div className="login-mark-sm">
            <Mark size={32} />
            Onélé
          </div>

          <h2>Connexion</h2>
          <p className="sub">Accédez à votre espace d’administration.</p>

          {error && (
            <div className="error-msg">
              <IconAlert size={16} />
              {error}
            </div>
          )}

          <div className="field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              required
              placeholder="vous@entreprise.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="username"
            />
          </div>

          <div className="field">
            <label htmlFor="password">Mot de passe</label>
            <input
              id="password"
              type="password"
              required
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
            />
          </div>

          <button className="btn block lg" type="submit" disabled={submitting} style={{ marginTop: 8 }}>
            {submitting && <span className="spinner" />}
            {submitting ? 'Connexion…' : 'Se connecter'}
          </button>

          <div className="login-hint">
            Compte de démonstration — <b>admin@onele.test</b> / <b>password</b>
          </div>
        </form>
      </main>
    </div>
  );
}
