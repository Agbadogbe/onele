const LABELS = {
  en_attente: ['En attente', 'pending'],
  validee: ['Validée', 'ok'],
  refusee: ['Refusée', 'no'],
};

export default function StatusBadge({ statut }) {
  const [label, tone] = LABELS[statut] ?? [statut, ''];
  return <span className={`badge ${tone}`}>{label}</span>;
}
