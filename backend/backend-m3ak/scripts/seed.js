/**
 * Script de seed pour la base Ma3ak
 * Utilisateurs inspirés des six protagonistes de Friends
 * Email: prenom.nom@gmail.com | Mot de passe: identique à l’email (hashé bcrypt)
 *
 * Connexion :
 * - .env à la racine (chargé automatiquement)
 * - MongoDB local : MONGODB_URI=mongodb://localhost:27017/ma3ak
 * - MongoDB Atlas : DB_USERNAME, DB_PASSWORD, DB_CLUSTER, DB_NAME (ou MONGODB_URI complète)
 *
 * Tests transport « Chauffeurs solidaires » : Joey & Chandler (connexion avec leur email).
 *
 * Usage: npm run seed
 */

const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Charger .env depuis la racine du projet
function loadEnv() {
  const envPath = path.join(process.cwd(), '.env');
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    content.split('\n').forEach((line) => {
      const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
      if (m) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    });
  }
}
loadEnv();

// URI MongoDB : MONGODB_URI directe, ou construction Atlas (DB_USERNAME, DB_PASSWORD, DB_CLUSTER, DB_NAME)
function getMongoUri() {
  const uri = process.env.MONGODB_URI;
  if (uri) return uri;

  const username = process.env.DB_USERNAME;
  const password = process.env.DB_PASSWORD;
  const cluster = process.env.DB_CLUSTER;
  const dbName = process.env.DB_NAME || 'ma3ak';

  if (username && password && cluster) {
    const encodedPassword = encodeURIComponent(password);
    return `mongodb+srv://${username}:${encodedPassword}@${cluster}/${dbName}?retryWrites=true&w=majority`;
  }

  return 'mongodb://localhost:27017/ma3ak';
}

const MONGODB_URI = getMongoUri();

/**
 * Les six protagonistes de Friends
 * - Joey & Chandler : ACCOMPAGNANT + type « Chauffeurs solidaires » (routes transport)
 * - Ross : autre type d’accompagnant
 * - Rachel & Phoebe : HANDICAPE
 * - Monica : ADMIN (backoffice / tests admin)
 */
const PERSONNAGES = [
  { prenom: 'Rachel', nom: 'Green', role: 'HANDICAPE' },
  { prenom: 'Monica', nom: 'Geller', role: 'ADMIN' },
  { prenom: 'Phoebe', nom: 'Buffay', role: 'HANDICAPE' },
  {
    prenom: 'Joey',
    nom: 'Tribbiani',
    role: 'ACCOMPAGNANT',
    typeAccompagnant: 'Chauffeurs solidaires',
  },
  {
    prenom: 'Chandler',
    nom: 'Bing',
    role: 'ACCOMPAGNANT',
    typeAccompagnant: 'Chauffeurs solidaires',
  },
  {
    prenom: 'Ross',
    nom: 'Geller',
    role: 'ACCOMPAGNANT',
    typeAccompagnant: 'Membres de la famille',
  },
];

// Les quatre types d'accompagnant autorisés (backend)
const TYPES_ACCOMPAGNANT = [
  'Chauffeurs solidaires',
  'Membres de la famille',
  'benevolat',
  'aide soignante',
];

function emailFromName(prenom, nom) {
  const n = `${prenom}.${nom}`.toLowerCase().replace(/\s+/g, '').replace(/'/g, '');
  return `${n}@gmail.com`;
}

// Schémas minimaux pour l'insertion (sans dépendre de Nest)
const UserSchema = new mongoose.Schema(
  {
    nom: { type: String, required: true },
    prenom: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    password: { type: String, required: true },
    telephone: { type: String, default: null },
    role: { type: String, enum: ['HANDICAPE', 'ACCOMPAGNANT', 'ADMIN'], required: true },
    typeHandicap: { type: String, default: null },
    besoinSpecifique: { type: String, default: null },
    animalAssistance: { type: Boolean, default: false },
    typeAccompagnant: { type: String, default: null },
    specialisation: { type: String, default: null },
    disponible: { type: Boolean, default: false },
    noteMoyenne: { type: Number, default: 0 },
    langue: { type: String, default: 'fr' },
    photoProfil: { type: String, default: null },
    statut: { type: String, default: 'ACTIF' },
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
    lastLocationAt: { type: Date, default: null },
  },
  { timestamps: true, versionKey: false, collection: 'users' }
);

const VehicleSchema = new mongoose.Schema(
  {
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    marque: { type: String, required: true },
    modele: { type: String, required: true },
    immatriculation: { type: String, required: true },
    accessibilite: {
      coffreVaste: { type: Boolean, default: false },
      rampeAcces: { type: Boolean, default: false },
      siegePivotant: { type: Boolean, default: false },
      climatisation: { type: Boolean, default: false },
      animalAccepte: { type: Boolean, default: false },
    },
    photos: { type: [String], default: [] },
    statut: { type: String, enum: ['EN_ATTENTE', 'VALIDE', 'REFUSE'], default: 'VALIDE' },
  },
  { timestamps: true, versionKey: false, collection: 'vehicles' }
);

const User = mongoose.model('User', UserSchema);
const Vehicle = mongoose.model('Vehicle', VehicleSchema);

async function seed() {
  console.log('Connexion à MongoDB...', MONGODB_URI);
  await mongoose.connect(MONGODB_URI);
  console.log('Connecté.\n');

  // Corriger les accompagnants déjà en base avec un typeAccompagnant invalide (ex. "transport")
  const toFix = await User.find({ role: 'ACCOMPAGNANT' }).exec();
  let fixCount = 0;
  for (let i = 0; i < toFix.length; i++) {
    const u = toFix[i];
    if (!u.typeAccompagnant || !TYPES_ACCOMPAGNANT.includes(u.typeAccompagnant)) {
      const newType = TYPES_ACCOMPAGNANT[i % TYPES_ACCOMPAGNANT.length];
      await User.updateOne(
        { _id: u._id },
        { $set: { typeAccompagnant: newType, updatedAt: new Date() } }
      ).exec();
      fixCount++;
      console.log(`  → typeAccompagnant corrigé: ${u.prenom} ${u.nom} → ${newType}`);
    }
  }
  if (fixCount > 0) console.log(`${fixCount} accompagnant(s) mis à jour.\n`);

  const createdUsers = [];
  const saltRounds = 10;
  let accompagnantIndex = 0;

  for (const p of PERSONNAGES) {
    const email = emailFromName(p.prenom, p.nom);
    const passwordPlain = email;
    const hashedPassword = await bcrypt.hash(passwordPlain, saltRounds);

    const existing = await User.findOne({ email }).exec();
    const isAccompagnant = p.role === 'ACCOMPAGNANT';
    const typeAccompagnantSeeded = isAccompagnant
      ? p.typeAccompagnant != null
        ? p.typeAccompagnant
        : TYPES_ACCOMPAGNANT[accompagnantIndex++ % TYPES_ACCOMPAGNANT.length]
      : null;
    // Tous les accompagnants « disponibles » (comme l’ancien seed) ; seuls les Chauffeurs solidaires passent le garde transport.
    const disponibleSeeded = isAccompagnant;

    if (existing) {
      const sync = {};
      if (isAccompagnant && typeAccompagnantSeeded && existing.typeAccompagnant !== typeAccompagnantSeeded) {
        sync.typeAccompagnant = typeAccompagnantSeeded;
      }
      if (isAccompagnant && disponibleSeeded !== undefined && existing.disponible !== disponibleSeeded) {
        sync.disponible = disponibleSeeded;
      }
      if (Object.keys(sync).length > 0) {
        sync.updatedAt = new Date();
        await User.updateOne({ _id: existing._id }, { $set: sync }).exec();
        console.log(`  → Profil mis à jour: ${email}`, sync);
      } else {
        console.log(`Utilisateur déjà existant: ${email} (${p.prenom} ${p.nom})`);
      }
      createdUsers.push({ ...p, email, _id: existing._id });
      continue;
    }

    const user = await User.create({
      nom: p.nom,
      prenom: p.prenom,
      email,
      password: hashedPassword,
      telephone: null,
      role: p.role,
      typeHandicap: p.role === 'HANDICAPE' ? 'mobilite_reduite' : null,
      besoinSpecifique: null,
      animalAssistance: false,
      typeAccompagnant: typeAccompagnantSeeded,
      specialisation: isAccompagnant ? 'mobilite_reduite' : null,
      disponible: Boolean(disponibleSeeded),
      noteMoyenne: isAccompagnant ? 4 + Math.random() : 0,
      langue: 'fr',
      photoProfil: null,
      statut: 'ACTIF',
      latitude: 36.8 + (Math.random() - 0.5) * 0.1,
      longitude: 10.18 + (Math.random() - 0.5) * 0.1,
      lastLocationAt: new Date(),
    });
    createdUsers.push({ ...p, email, _id: user._id });
    console.log(`Créé: ${p.prenom} ${p.nom} — ${email} (rôle: ${p.role})`);
  }

  // Véhicules pour les Chauffeurs solidaires (courses transport)
  const vehiculesData = [
    {
      ownerPrenom: 'Joey',
      marque: 'Toyota',
      modele: 'Rav4',
      immat: 'JOEY TUN 1994',
      rampe: true,
    },
    {
      ownerPrenom: 'Chandler',
      marque: 'Mercedes',
      modele: 'Vito',
      immat: 'CHAN TUN 1995',
      rampe: true,
    },
  ];
  for (const v of vehiculesData) {
    const owner = createdUsers.find((u) => u.prenom === v.ownerPrenom);
    if (!owner) continue;
    const exists = await Vehicle.findOne({ ownerId: owner._id, immatriculation: v.immat }).exec();
    if (!exists) {
      await Vehicle.create({
        ownerId: owner._id,
        marque: v.marque,
        modele: v.modele,
        immatriculation: v.immat,
        accessibilite: { coffreVaste: true, rampeAcces: v.rampe, siegePivotant: true, climatisation: true, animalAccepte: true },
        photos: [],
        statut: 'VALIDE',
      });
      console.log(`  → Véhicule créé: ${v.marque} ${v.modele} (${owner.prenom} ${owner.nom})`);
    }
  }

  console.log('\n--- Récapitulatif ---');
  console.log(
    `Utilisateurs Friends: ${createdUsers.length} — email = prenom.nom@gmail.com, mot de passe identique à l’email.`,
  );
  console.log('Transport (Chauffeurs solidaires): joey.tribbiani@gmail.com | chandler.bing@gmail.com');
  console.log('Admin: monica.geller@gmail.com');
  console.log('Fin du seed.');
}

seed()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => {
    mongoose.disconnect();
    process.exit(0);
  });
