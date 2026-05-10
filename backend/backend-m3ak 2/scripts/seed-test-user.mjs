/**
 * Crée un utilisateur de test via l'API (dev uniquement).
 * Prérequis : API démarrée (npm run start:dev)
 *
 * Usage : npm run seed:dev
 * Variables : API_URL (défaut http://localhost:3000)
 *
 * Chemin backend (exemple machine locale) :
 *   cd "C:\Users\DELL\Downloads\backend-m3ak\backend-m3ak 2"
 */

const base = process.env.API_URL || 'http://localhost:3000';

// Email simple (TLD .com + partie locale sans point) : évite les rejets @IsEmail()
// (ex. dev@test.ma3ak → domaine "test.ma3ak" souvent invalide).
const user = {
  nom: 'Test',
  prenom: 'Dev',
  email: 'ma3akdev@example.com',
  password: 'Test123!',
  telephone: '+21600000000',
  role: 'HANDICAPE',
  typeHandicap: 'VISUEL',
};

async function main() {
  const url = `${base.replace(/\/$/, '')}/user/register`;
  const payload = JSON.stringify(user);
  console.log('POST', url);
  console.log('Body :', payload);
  console.log('');
  console.log('Si tu vois encore "Email invalide", vérifie que ce fichier contient bien');
  console.log('email: "ma3akdev@example.com" (pas dev@test.ma3ak).');

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: payload,
  });

  const text = await res.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    data = text;
  }

  if (res.status === 201) {
    console.log('OK — compte créé.');
    console.log('  Email   :', user.email);
    console.log('  Password:', user.password);
    console.log('Connecte-toi dans l’app avec ces identifiants.');
    return;
  }

  if (res.status === 409) {
    console.log('Le compte existe déjà (409). Utilise le même email / mot de passe dans l’app :');
    console.log('  Email   :', user.email);
    console.log('  Password:', user.password);
    return;
  }

  console.error('Erreur', res.status, data);
  process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
