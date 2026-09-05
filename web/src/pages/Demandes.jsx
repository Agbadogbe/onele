import { useEffect, useRef, useState } from 'react';
import { api } from '../api';
import { useRealtimeEvent } from '../context/RealtimeContext';
import { useToast } from '../components/Toast';
import Modal from '../components/Modal';
import StatusBadge from '../components/StatusBadge';
import TypeChip from '../components/TypeChip';
import Avatar from '../components/Avatar';
import EmptyState from '../components/EmptyState';
import TableSkeleton from '../components/Skeleton';
import { IconCheck, IconX } from '../components/Icons';
import { capitaliser, formatDate } from '../format';

const TABS = [
  { key: 'toutes', label: 'Toutes' },
  { key: 'en_attente', label: 'En attente' },
  { key: 'conge', label: 'Congé' },
  { key: 'permission', label: 'Permission' },
  { key: 'materiel', label: 'Matériel' },
];

const TYPE_LABELS = { conge: 'Congé', permission: 'Permission', materiel: 'Matériel' };

/** L'API renvoie « 14:00:00 » ; on n'affiche que les heures et minutes. */
function heure(valeur) {
  return valeur ? valeur.slice(0, 5) : '';
}

function detailLabel(demande) {
  const d = demande.detail;
  if (!d) return '—';
  if (demande.type === 'conge') return `${capitaliser(d.type_conge)} · ${d.nombre_jours} j`;
  if (demande.type === 'permission') return `${heure(d.heure_debut)} – ${heure(d.heure_fin)} · ${d.motif}`;
  if (demande.type === 'materiel') return `${d.materiel?.nom} ×${d.quantite}`;
  return '—';
}

/** Une demande poussée en direct n'est insérée que si l'onglet courant la montre. */
function correspondAuFiltre(demande, tab) {
  if (tab === 'toutes') return true;
  if (tab === 'en_attente') return demande.statut === 'en_attente';
  return demande.type === tab;
}

function periode(demande) {
  if (demande.date_debut === demande.date_fin) return formatDate(demande.date_debut);
  return `${formatDate(demande.date_debut)} → ${formatDate(demande.date_fin)}`;
}

export default function Demandes() {
  const [demandes, setDemandes] = useState([]);
  const [tab, setTab] = useState('toutes');
  const [loading, setLoading] = useState(true);
  const [decision, setDecision] = useState(null); // { demande, statut }
  const [commentaire, setCommentaire] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [recentes, setRecentes] = useState(() => new Set());
  const minuteries = useRef([]);
  const notify = useToast();

  /** Souligne brièvement une ligne qui vient de bouger, pour que l'œil la suive. */
  function signaler(id) {
    setRecentes((precedentes) => new Set(precedentes).add(id));
    const minuterie = setTimeout(
      () => setRecentes((precedentes) => {
        const suite = new Set(precedentes);
        suite.delete(id);
        return suite;
      }),
      2600,
    );
    minuteries.current.push(minuterie);
  }

  useEffect(() => () => minuteries.current.forEach(clearTimeout), []);

  // Une demande déposée depuis le mobile apparaît en tête, sans rechargement.
  useRealtimeEvent('demande.deposee', ({ demande }) => {
    if (!correspondAuFiltre(demande, tab)) return;
    setDemandes((liste) =>
      liste.some((d) => d.id === demande.id) ? liste : [demande, ...liste],
    );
    signaler(demande.id);
  });

  // Verdict rendu ici ou par un autre poste RH : la ligne se met à jour en place,
  // ou quitte la liste si l'onglet ne montre que les demandes en attente.
  useRealtimeEvent('demande.traitee', ({ demande }) => {
    setDemandes((liste) => {
      if (!liste.some((d) => d.id === demande.id)) return liste;
      if (!correspondAuFiltre(demande, tab)) return liste.filter((d) => d.id !== demande.id);
      return liste.map((d) => (d.id === demande.id ? demande : d));
    });
    signaler(demande.id);
  });

  function load() {
    setLoading(true);
    const params = tab === 'toutes' ? {} : ['en_attente'].includes(tab) ? { statut: tab } : { type: tab };
    api.demandes(params).then(setDemandes).catch(() => {}).finally(() => setLoading(false));
  }

  useEffect(load, [tab]);

  function openDecision(demande, statut) {
    setCommentaire('');
    setDecision({ demande, statut });
  }

  async function confirmDecision() {
    setSubmitting(true);
    try {
      await api.updateDemandeStatut(decision.demande.id, {
        statut: decision.statut,
        commentaire: commentaire || undefined,
      });
      notify(decision.statut === 'validee' ? 'Demande validée.' : 'Demande refusée.');
      setDecision(null);
      // Pas de rechargement : l'évènement `demande.traitee` met la ligne à jour,
      // ici comme sur le mobile de l'employé.
    } catch (err) {
      notify(err.message, 'error');
    } finally {
      setSubmitting(false);
    }
  }

  const valide = decision?.statut === 'validee';
  const enAttente = demandes.filter((d) => d.statut === 'en_attente').length;

  return (
    <div className="page">
      <div className="page-head">
        <div>
          <h1>Demandes</h1>
          <p className="page-sub">Congés, permissions et matériel soumis par les employés.</p>
        </div>
        {!loading && enAttente > 0 && (
          <span className="badge pending" style={{ fontSize: '.8rem', padding: '6px 14px 6px 11px' }}>
            {enAttente} en attente de décision
          </span>
        )}
      </div>

      <div className="tabs">
        {TABS.map((t) => (
          <button
            key={t.key}
            className={`tab ${tab === t.key ? 'active' : ''}`}
            onClick={() => setTab(t.key)}
          >
            {t.label}
            {tab === t.key && !loading && <span className="n">{demandes.length}</span>}
          </button>
        ))}
      </div>

      <div className="card">
        {loading ? (
          <TableSkeleton rows={5} />
        ) : demandes.length === 0 ? (
          <EmptyState
            titre="Aucune demande ici"
            texte="Changez de filtre ou attendez qu’un employé dépose une demande depuis l’application mobile."
          />
        ) : (
          <div className="table-wrap">
            <table className="data">
              <thead>
                <tr>
                  <th>Employé</th>
                  <th>Type</th>
                  <th>Période</th>
                  <th>Détail</th>
                  <th>Statut</th>
                  <th className="right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {demandes.map((d, i) => (
                  <tr
                    key={d.id}
                    data-statut={d.statut}
                    className={recentes.has(d.id) ? 'flash' : undefined}
                    style={{ animationDelay: `${Math.min(i, 12) * 35}ms` }}
                  >
                    <td>
                      <div className="who-cell">
                        <Avatar prenom={d.utilisateur?.prenom} nom={d.utilisateur?.nom} />
                        <span className="who-txt">
                          <strong>{d.utilisateur?.prenom} {d.utilisateur?.nom}</strong>
                          <span>#{d.id}</span>
                        </span>
                      </div>
                    </td>
                    <td data-label="Type"><TypeChip type={d.type} /></td>
                    <td data-label="Période" className="muted nowrap nums">{periode(d)}</td>
                    <td data-label="Détail" className="detail-cell">{detailLabel(d)}</td>
                    <td data-label="Statut"><StatusBadge statut={d.statut} /></td>
                    <td className="right">
                      {d.statut === 'en_attente' ? (
                        <div className="row-actions">
                          <button className="btn sm ok" onClick={() => openDecision(d, 'validee')}>
                            <IconCheck size={13} />
                            Valider
                          </button>
                          <button className="btn sm danger" onClick={() => openDecision(d, 'refusee')}>
                            <IconX size={13} />
                            Refuser
                          </button>
                        </div>
                      ) : (
                        <span className="muted" style={{ fontSize: '.8rem' }}>
                          {d.validateur ? `par ${d.validateur.prenom} ${d.validateur.nom}` : '—'}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {decision && (
        <Modal
          title={valide ? 'Valider la demande' : 'Refuser la demande'}
          onClose={() => setDecision(null)}
          footer={
            <>
              <button className="btn ghost" onClick={() => setDecision(null)}>Annuler</button>
              <button
                className={`btn ${valide ? 'ok' : 'danger'}`}
                onClick={confirmDecision}
                disabled={submitting}
              >
                {submitting && <span className="spinner" />}
                {submitting ? 'Envoi…' : valide ? 'Valider la demande' : 'Refuser la demande'}
              </button>
            </>
          }
        >
          <div className="recap">
            <Avatar
              prenom={decision.demande.utilisateur?.prenom}
              nom={decision.demande.utilisateur?.nom}
              size="lg"
            />
            <span className="txt">
              <strong>{decision.demande.utilisateur?.prenom} {decision.demande.utilisateur?.nom}</strong>
              <span>
                {TYPE_LABELS[decision.demande.type] ?? decision.demande.type} · {periode(decision.demande)}
              </span>
            </span>
          </div>

          <p className="muted" style={{ fontSize: '.86rem', marginBottom: 16 }}>
            {valide
              ? 'L’employé sera notifié de la validation.'
              : 'L’employé sera notifié du refus. Un motif l’aidera à comprendre la décision.'}
          </p>

          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="commentaire">Commentaire (optionnel)</label>
            <textarea
              id="commentaire"
              rows={3}
              placeholder={valide ? 'Accord donné, bonne organisation !' : 'Période trop chargée, merci de reporter…'}
              value={commentaire}
              onChange={(e) => setCommentaire(e.target.value)}
            />
          </div>
        </Modal>
      )}
    </div>
  );
}
