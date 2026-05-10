/* eslint-disable no-console */
const { MongoClient } = require('mongodb');

function normalizeTunisiaPhone(raw) {
  if (!raw || typeof raw !== 'string') return null;
  const trimmed = raw.trim();
  if (!trimmed) return null;

  const hasPlus = trimmed.startsWith('+');
  let compact = trimmed.replace(/[^\d+]/g, '');
  if (!hasPlus) {
    compact = compact.replace(/\+/g, '');
  } else {
    compact = `+${compact.slice(1).replace(/\+/g, '')}`;
  }

  const digitsOnly = compact.replace(/\D/g, '');
  if (/^\d{8}$/.test(digitsOnly)) return `+216${digitsOnly}`;
  if (/^216\d{8}$/.test(digitsOnly)) return `+${digitsOnly}`;
  if (/^\+216\d{8}$/.test(compact)) return compact;
  return hasPlus ? `+${digitsOnly}` : digitsOnly;
}

async function run() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/ma3ak';
  const client = new MongoClient(uri);
  await client.connect();
  const dbName = (() => {
    try {
      const parsed = new URL(uri);
      return (parsed.pathname || '/ma3ak').replace('/', '') || 'ma3ak';
    } catch {
      return 'ma3ak';
    }
  })();

  const db = client.db(dbName);
  const users = db.collection('users');

  const cursor = users.find({}, { projection: { telephone: 1 } });
  let updated = 0;

  while (await cursor.hasNext()) {
    const doc = await cursor.next();
    const normalized = normalizeTunisiaPhone(doc?.telephone || null);
    await users.updateOne(
      { _id: doc._id },
      { $set: { telephoneNormalized: normalized } },
    );
    updated += 1;
  }

  await users.createIndex({ telephoneNormalized: 1 });
  console.log(`Normalization done. Updated ${updated} user(s).`);
  await client.close();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
