/**
 * Test rapide de Google Cloud Vision API (labelDetection sur une image distante).
 *
 * Prérequis :
 *   - npm install @google-cloud/vision
 *   - Compte de service + JSON, variable GOOGLE_APPLICATION_CREDENTIALS dans .env
 *     ou exportée dans le shell (voir docs/SETUP_GOOGLE_VISION_FR.md)
 *
 * Lancement : npm run test:vision
 *             ou : node testVision.js
 *
 * Variables (PowerShell) :
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:/secrets/ma-cle.json"
 *   $env:GOOGLE_CLOUD_PROJECT_ID="mon-project-id"
 */

const vision = require('@google-cloud/vision');

// Remplace par ton Project ID GCP, ou définis GOOGLE_CLOUD_PROJECT_ID dans .env
const projectId =
  process.env.GOOGLE_CLOUD_PROJECT_ID || 'ma3ak-vision-123456';

const client = new vision.ImageAnnotatorClient({
  projectId,
});

async function testVision() {
  const imageUri =
    'https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png';

  try {
    const [result] = await client.labelDetection({
      image: {
        source: { imageUri },
      },
    });

    const labels = result.labelAnnotations || [];
    console.log('Labels détectés :');
    labels.forEach((label, i) => {
      console.log(
        `  ${i + 1}. ${label.description} (score: ${(label.score * 100).toFixed(1)}%)`,
      );
    });
    if (labels.length === 0) {
      console.log('  (aucun label)');
    }
  } catch (err) {
    console.error('Erreur Vision API :', err.message);
    if (err.code) console.error('  code:', err.code);
    process.exitCode = 1;
  }
}

testVision();
