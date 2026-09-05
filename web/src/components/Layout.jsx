import { useEffect, useState } from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { api } from '../api';
import { useAuth } from '../context/AuthContext';
import { useRealtime, useRealtimeEvent } from '../context/RealtimeContext';
import { useToast } from './Toast';
import Avatar from './Avatar';
import Mark from './Mark';
import {
  IconDashboard,
  IconInbox,
  IconUsers,
  IconBox,
  IconHistory,
  IconLogout,
} from './Icons';

const LINKS = [
  { to: '/', label: 'Tableau de bord', icon: IconDashboard, end: true },
  { to: '/demandes', label: 'Demandes', icon: IconInbox },
  { to: '/utilisateurs', label: 'Utilisateurs', icon: IconUsers },
  { to: '/materiel', label: 'Matériel', icon: IconBox },
  { to: '/historique', label: 'Historique', icon: IconHistory },
];

const ROLES = { admin: 'Administrateur', rh: 'RH', employe: 'Employé' };
const TYPES = { conge: 'congé', permission: 'permission', materiel: 'matériel' };

export default function Layout() {
  const { user, logout } = useAuth();
  const { connecte } = useRealtime();
  const [enAttente, setEnAttente] = useState(null);
  const notify = useToast();

  // Le compteur du rail est chargé une fois puis entretenu par les diffusions :
  // il reste juste quelle que soit la page ouverte.
  useEffect(() => {
    api
      .demandes({ statut: 'en_attente' })
      .then((liste) => setEnAttente(liste.length))
      .catch(() => {});
  }, []);

  useRealtimeEvent('demande.deposee', ({ demande }) => {
    setEnAttente((n) => (n ?? 0) + 1);
    const qui = `${demande.utilisateur?.prenom ?? ''} ${demande.utilisateur?.nom ?? ''}`.trim();
    notify(`Nouvelle demande de ${TYPES[demande.type] ?? demande.type} — ${qui}`);
  });

  useRealtimeEvent('demande.traitee', () => {
    setEnAttente((n) => Math.max(0, (n ?? 1) - 1));
  });

  return (
    <div className="shell">
      <aside className="rail">
        <div className="rail-brand">
          <Mark size={34} />
          <span className="name">
            Onélé
            <small>Administration</small>
          </span>
        </div>

        <span className={`live ${connecte ? 'on' : 'off'}`} title={
          connecte
            ? 'Connecté au serveur temps réel : les demandes arrivent sans rechargement.'
            : 'Temps réel indisponible — pensez à lancer « php artisan reverb:start ».'
        }>
          <i />
          <span className="txt">{connecte ? 'En direct' : 'Hors ligne'}</span>
        </span>

        <ul className="nav">
          {LINKS.map(({ to, label, icon: Icon, end }) => (
            <li key={to}>
              <NavLink to={to} end={end} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Icon size={17} />
                {label}
                {to === '/demandes' && enAttente > 0 && <span className="nav-count">{enAttente}</span>}
              </NavLink>
            </li>
          ))}
        </ul>

        <div className="rail-foot">
          <div className="rail-user">
            <Avatar prenom={user?.prenom} nom={user?.nom} size="sm" />
            <span className="who">
              <strong>{user?.prenom} {user?.nom}</strong>
              <span>{ROLES[user?.role] ?? user?.role}</span>
            </span>
          </div>
          <button className="rail-logout" onClick={logout} title="Se déconnecter">
            <IconLogout size={15} />
            <span className="txt">Se déconnecter</span>
          </button>
        </div>
      </aside>

      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
