import { TypeIcon } from './Icons';

const LABELS = { conge: 'Congé', permission: 'Permission', materiel: 'Matériel' };

export default function TypeChip({ type }) {
  return (
    <span className={`type-chip ${type}`}>
      <TypeIcon type={type} size={13} />
      {LABELS[type] ?? type}
    </span>
  );
}
