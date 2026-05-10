'use strict';

const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const { MongoClient, ObjectId } = require('mongodb');

const envPath = path.join(__dirname, 'backend', 'backend-m3ak 2', '.env');
dotenv.config({ path: envPath });

const uri = process.env.MONGODB_URI;

/** Hex 24 caractères = ObjectId sérialisé depuis le seed JSON */
function looksLikeObjectId(s) {
  return typeof s === 'string' && /^[a-fA-F0-9]{24}$/.test(s);
}

function toObjectIdMaybe(value) {
  if (value == null || value === '') return value;
  if (value instanceof ObjectId) return value;
  if (typeof value === 'object' && value.$oid != null && looksLikeObjectId(String(value.$oid))) {
    return new ObjectId(value.$oid);
  }
  if (looksLikeObjectId(value)) return new ObjectId(value);
  return value;
}

/** Prépare un document exporté depuis Mongo / JSON pour insertMany natif */
function preparePost(raw) {
  const d = { ...raw };

  delete d._seedKey;

  if (d._id != null) {
    const id = toObjectIdMaybe(d._id);
    if (id instanceof ObjectId) d._id = id;
  }

  d.userId = toObjectIdMaybe(d.userId);

  if (Array.isArray(d.merciUserIds)) {
    d.merciUserIds = d.merciUserIds.map((x) => toObjectIdMaybe(x)).filter((x) => x instanceof ObjectId);
  }
  if (Array.isArray(d.obstacleVoterIds)) {
    d.obstacleVoterIds = d.obstacleVoterIds.map((x) => toObjectIdMaybe(x)).filter((x) => x instanceof ObjectId);
  }

  if (d.linkedLieuId != null && d.linkedLieuId !== '') {
    const lk = toObjectIdMaybe(d.linkedLieuId);
    d.linkedLieuId = lk instanceof ObjectId ? lk : d.linkedLieuId;
  }

  if (typeof d.createdAt === 'string') d.createdAt = new Date(d.createdAt);
  if (typeof d.updatedAt === 'string') d.updatedAt = new Date(d.updatedAt);

  return d;
}

async function main() {
  if (!uri) {
    console.error(`MONGODB_URI absente ou introuvable. Vérifiez le fichier :\n${envPath}`);
    process.exit(1);
  }

  const postsPath = path.join(__dirname, 'seed', 'posts.json');
  if (!fs.existsSync(postsPath)) {
    console.error(`Fichier manquant : ${postsPath}`);
    process.exit(1);
  }

  const rawList = JSON.parse(fs.readFileSync(postsPath, 'utf8'));
  if (!Array.isArray(rawList)) {
    console.error('posts.json doit contenir un tableau de posts.');
    process.exit(1);
  }

  const docs = rawList.map(preparePost);

  const client = new MongoClient(uri);
  try {
    await client.connect();
    const col = client.db().collection('posts');

    await col.deleteMany({});
    const result = await col.insertMany(docs);

    console.log(`${result.insertedCount} post(s) injecté(s).`);
  } finally {
    await client.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
