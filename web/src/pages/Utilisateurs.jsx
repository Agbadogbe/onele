import { useEffect, useState } from 'react';
import { api } from '../api';
import { useToast } from '../components/Toast';
import Modal from '../components/Modal';
import Avatar from '../components/Avatar';
import EmptyState from '../components/EmptyState';
import TableSkeleton from '../components/Skeleton';
import { IconAlert, IconPlus, IconShield, IconUsers } from '../components/Icons';

const EMPTY_FORM = { nom: '', prenom: '', email: '', telephone: '', role: 'employe', password: '' };
const ROLES = { admin: 'Administrateur', rh: 'RH', employe: 'Employé' };

export default function Utilisateurs() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(null); // null | 'new' | user
  const [form, setForm] = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const notify = useToast();

  function load() {
    api.utilisateurs().then(setUsers).catch(() => {}).finally(() => setLoading(false));
  }

  useEffect(load, []);

  function openNew() {
    setForm(EMPTY_FORM);
    setError(null);
    setEditing('new');
  }

  function openEdit(user) {
    setForm({ ...user, password: '' });
    setError(null);
    setEditing(user);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      if (editing === 'new') {
        await api.createUtilisateur(form);
        notify('Utilisateur créé.');
      } else {
        const payload = { ...form };
        if (!payload.password) delete payload.password;
        await api.updateUtilisateur(editing.id, payload);
        notify('Utilisateur mis à jour.');
      }
      setEditing(null);
      load();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDeactivate(user) {
    if (!confirm(`Désactiver le compte de ${user.prenom} ${user.nom} ?`)) return;
    try {
      await api.deactivateUtilisateur(user.id);
      notify('Utilisateur désactivé.');
      load();
    } catch (err) {
      notify(err.message, 'error');
    }
  }

  const actifs = users.filter((u) => u.actif).length;

  return (
    <div className="page">
      <div className="page-head">
        <div>
          <h1>Utilisateurs</h1>
          <p className="page-sub">Comptes employés et administrateurs.</p>
        </div>
        <button className="btn" onClick={openNew}>
          <IconPlus size={15} />
          Nouvel utilisateur
        </button>
      </div>

      {!loading && users.length > 0 && (
        <p className="eyebrow" style={{ marginBottom: 14 }}>
          {users.length} compte{users.length > 1 ? 's' : ''} · {actifs} actif{actifs > 1 ? 's' : ''}
        </p>
      )}

      <div className="card">
        {loading ? (
          <TableSkeleton rows={4} />
        ) : users.length === 0 ? (
          <EmptyState
            titre="Aucun utilisateur"
            texte="Créez le premier compte pour permettre à vos équipes de déposer des demandes."
            icon={<IconUsers size={22} />}
            action={<button className="btn" onClick={openNew}><IconPlus size={15} />Nouvel utilisateur</button>}
          />
        ) : (
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Nom</th>
                  <th>Contact</th>
                  <th>Rôle</th>
                  <th>Statut</th>
                  <th className="right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u, i) => (
                  <tr key={u.id} style={{ animationDelay: `${Math.min(i, 12) * 35}ms` }}>
                    <td>
                      <div className="who-cell">
                        <Avatar prenom={u.prenom} nom={u.nom} />
                        <span className="who-txt">
                          <strong>{u.prenom} {u.nom}</strong>
                          <span>{u.email}</span>
                        </span>
                      </div>
                    </td>
                    <td data-label="Téléphone" className="muted nowrap">{u.telephone || '—'}</td>
                    <td data-label="Rôle">
                      <span className={`role-chip ${u.role === 'admin' ? 'admin' : ''}`}>
                        {u.role === 'admin' && <IconShield size={11} />}
                        {ROLES[u.role] ?? u.role}
                      </span>
                    </td>
                    <td data-label="Statut">
                      <span className={`badge ${u.actif ? 'ok' : 'no'}`}>{u.actif ? 'Actif' : 'Désactivé'}</span>
                    </td>
                    <td className="right">
                      <div className="row-actions">
                        <button className="btn sm ghost" onClick={() => openEdit(u)}>Modifier</button>
                        {u.actif && (
                          <button className="btn sm danger" onClick={() => handleDeactivate(u)}>Désactiver</button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {editing && (
        <Modal
          title={editing === 'new' ? 'Nouvel utilisateur' : `Modifier ${editing.prenom} ${editing.nom}`}
          onClose={() => setEditing(null)}
          footer={
            <>
              <button type="button" className="btn ghost" onClick={() => setEditing(null)}>Annuler</button>
              <button type="submit" form="user-form" className="btn" disabled={submitting}>
                {submitting && <span className="spinner" />}
                {submitting ? 'Enregistrement…' : 'Enregistrer'}
              </button>
            </>
          }
        >
          <form id="user-form" onSubmit={handleSubmit}>
            {error && (
              <div className="error-msg">
                <IconAlert size={16} />
                {error}
              </div>
            )}

            <div className="field-row">
              <div className="field">
                <label>Prénom</label>
                <input required value={form.prenom} onChange={(e) => setForm({ ...form, prenom: e.target.value })} />
              </div>
              <div className="field">
                <label>Nom</label>
                <input required value={form.nom} onChange={(e) => setForm({ ...form, nom: e.target.value })} />
              </div>
            </div>

            <div className="field">
              <label>Email</label>
              <input type="email" required placeholder="prenom.nom@entreprise.com" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
            </div>

            <div className="field">
              <label>Téléphone</label>
              <input placeholder="Optionnel" value={form.telephone ?? ''} onChange={(e) => setForm({ ...form, telephone: e.target.value })} />
            </div>

            <div className="field">
              <label>Rôle</label>
              <select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })}>
                <option value="employe">Employé — dépose ses demandes</option>
                <option value="rh">RH — traite les demandes</option>
                <option value="admin">Administrateur — accès complet</option>
              </select>
            </div>

            <div className="field" style={{ marginBottom: 0 }}>
              <label>{editing === 'new' ? 'Mot de passe' : 'Nouveau mot de passe'}</label>
              <input
                type="password"
                required={editing === 'new'}
                placeholder={editing === 'new' ? '8 caractères minimum' : 'Laisser vide pour ne pas changer'}
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
              />
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
