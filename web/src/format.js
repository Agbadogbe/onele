/** Formatage à la française — l'API renvoie des dates ISO (2026-09-04). */

export function formatDate(iso) {
  if (!iso) return '—';
  const [annee, mois, jour] = iso.slice(0, 10).split('-');
  return `${jour}/${mois}/${annee}`;
}

/** « annuel » → « Annuel ». */
export function capitaliser(texte) {
  if (!texte) return texte;
  return texte.charAt(0).toUpperCase() + texte.slice(1);
}
