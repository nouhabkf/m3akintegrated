'use strict';

const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const { MongoClient, ObjectId } = require('mongodb');

dotenv.config({ path: path.join(__dirname, '.env') });
if (!process.env.MONGODB_URI) {
  dotenv.config({
    path: path.join(__dirname, 'backend', 'backend-m3ak 2', '.env'),
  });
}

const uri = process.env.MONGODB_URI;

/** Sérialisation des ObjectId pour un JSON lisible / ré-importable */
function bsonReplacer(_key, value) {
  if (value instanceof ObjectId) return { $oid: value.toString() };
  return value;
}

async function main() {
  if (!uri) {
    console.error(
      'Variable MONGODB_URI absente : définissez-la dans .env à la racine ou backend/backend-m3ak 2/.env',
    );
    process.exit(1);
  }

  const seedDir = path.join(__dirname, 'seed');
  const outPath = path.join(seedDir, 'posts.json');

  fs.mkdirSync(seedDir, { recursive: true });

  const client = new MongoClient(uri);

  try {
    await client.connect();
    const db = client.db();
    const docs = await db.collection('posts').find({}).toArray();
    const json =
      JSON.stringify(docs, bsonReplacer, 2) + (docs.length ? '\n' : '');

    fs.writeFileSync(outPath, json, 'utf8');
    console.log(`${docs.length} post(s) exporté(s) → ${path.relative(process.cwd(), outPath)}`);
  } finally {
    await client.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
