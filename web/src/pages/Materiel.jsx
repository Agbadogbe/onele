import { useEffect, useState } from 'react';
import { api } from '../api';
import { useToast } from '../components/Toast';
import Modal from '../components/Modal';
import EmptyState from '../components/EmptyState';
import TableSkeleton from '../components/Skeleton';
import { IconAlert, IconBox, IconPlus } from '../components/Icons';

const EMPTY_FORM = { nom: '', categorie: '', description: '', quantite_disponible: 0 };

/** Seuil bas arbitraire : en dessous de 3 unités, on signale le stock. */
function niveauStock(quantite) {
  if (quantite === 0) return 'out';
  if (quantite <= 3) return 'low';
  return '';
}

export default function Materiel() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(null); // null | 'new' | item
  const [form, setForm] = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const notify = useToast();

  function load() {
    api.materiels().then(setItems).catch(() => {}).finally(() => setLoading(false));
  }

  useEffect(load, []);

  function openNew() {
    setForm(EMPTY_FORM);
    setError(null);
    setEditing('new');
  }

  function openEdit(item) {
    setForm(item);
    setError(null);
    setEditing(item);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const payload = { ...form, quantite_disponible: Number(form.quantite_disponible) };
      if (editing === 'new') {
        await api.createMateriel(payload);
        notify('Matériel ajouté.');
      } else {
        await api.updateMateriel(editing.id, payload);
        notify('Matériel mis à jour.');
      }
      setEditing(null);
      load();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(item) {
    if (!confirm(`Supprimer "${item.nom}" ?`)) return;
    try {
      await api.deleteMateriel(item.id);
      notify('Matériel supprimé.');
      load();
    } catch (err) {
      notify(err.message, 'error');
    }
  }

  const maxStock = Math.max(1, ...items.map((m) => m.quantite_disponible));
  const rupture = items.filter((m) => m.quantite_disponible === 0).length;

  return (
    <div className="page">
      <div className="page-head">
        <div>
          <h1>Matériel</h1>
          <p className="page-sub">Inventaire disponible pour les demandes des employés.</p>
        </div>
        <button className="btn" onClick={openNew}>
          <IconPlus size={15} />
          Ajouter un matériel
        </button>
      </div>

      {!loading && items.length > 0 && (
        <p className="eyebrow" style={{ marginBottom: 14 }}>
          {items.length} référence{items.length > 1 ? 's' : ''}
          {rupture > 0 && ` · ${rupture} en rupture`}
        </p>
      )}

      <div className="card">
        {loading ? (
          <TableSkeleton rows={4} avatar={false} />
        ) : items.length === 0 ? (
          <EmptyState
            titre="Inventaire vide"
            texte="Ajoutez du matériel pour que les employés puissent en faire la demande."
            icon={<IconBox size={22} />}
            action={<button className="btn" onClick={openNew}><IconPlus size={15} />Ajouter un matériel</button>}
          />
        ) : (
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Matériel</th>
                  <th>Catégorie</th>
                  <th>Stock disponible</th>
                  <th className="right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((m, i) => {
                  const niveau = niveauStock(m.quantite_disponible);
                  return (
                    <tr key={m.id} style={{ animationDelay: `${Math.min(i, 12) * 35}ms` }}>
                      <td>
                        <strong style={{ fontWeight: 500 }}>{m.nom}</strong>
                        {m.description && (
                          <div className="muted" style={{ fontSize: '.79rem' }}>{m.description}</div>
                        )}
                      </td>
                      <td data-label="Catégorie">
                        <span className="role-chip">{m.categorie || 'Non classé'}</span>
                      </td>
                      <td data-label="Stock">
                        <div className={`stock ${niveau}`}>
                          <span className="n">{m.quantite_disponible}</span>
                          <span className="gauge">
                            <i style={{ width: `${(m.quantite_disponible / maxStock) * 100}%` }} />
                          </span>
                        </div>
                      </td>
                      <td className="right">
                        <div className="row-actions">
                          <button className="btn sm ghost" onClick={() => openEdit(m)}>Modifier</button>
                          <button className="btn sm danger" onClick={() => handleDelete(m)}>Supprimer</button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {editing && (
        <Modal
          title={editing === 'new' ? 'Nouveau matériel' : `Modifier ${editing.nom}`}
          onClose={() => setEditing(null)}
          footer={
            <>
              <button type="button" className="btn ghost" onClick={() => setEditing(null)}>Annuler</button>
              <button type="submit" form="materiel-form" className="btn" disabled={submitting}>
                {submitting && <span className="spinner" />}
                {submitting ? 'Enregistrement…' : 'Enregistrer'}
              </button>
            </>
          }
        >
          <form id="materiel-form" onSubmit={handleSubmit}>
            {error && (
              <div className="error-msg">
                <IconAlert size={16} />
                {error}
              </div>
            )}

            <div className="field">
              <label>Nom</label>
              <input required placeholder="Ordinateur portable" value={form.nom} onChange={(e) => setForm({ ...form, nom: e.target.value })} />
            </div>

            <div className="field">
              <label>Catégorie</label>
              <input placeholder="Informatique, Mobilier…" value={form.categorie ?? ''} onChange={(e) => setForm({ ...form, categorie: e.target.value })} />
            </div>

            <div className="field">
              <label>Description</label>
              <textarea rows={2} placeholder="Optionnel" value={form.description ?? ''} onChange={(e) => setForm({ ...form, description: e.target.value })} />
            </div>

            <div className="field" style={{ marginBottom: 0 }}>
              <label>Quantité disponible</label>
              <input
                type="number"
                min="0"
                required
                value={form.quantite_disponible}
                onChange={(e) => setForm({ ...form, quantite_disponible: e.target.value })}
              />
              <span className="hint">Nombre d’unités que les employés peuvent réserver.</span>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
