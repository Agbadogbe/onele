/**
 * Pastille d'initiales. La teinte est dérivée du nom, donc une même personne
 * garde toujours la même couleur d'un écran à l'autre.
 */
export default function Avatar({ prenom = '', nom = '', size = '' }) {
  const initiales = `${prenom.charAt(0)}${nom.charAt(0)}` || '?';
  const graine = [...`${prenom}${nom}`].reduce((acc, c) => acc + c.charCodeAt(0), 0);
  const teinte = `a${graine % 6}`;

  return (
    <span className={`avatar ${size} ${teinte}`} aria-hidden="true">
      {initiales}
    </span>
  );
}
