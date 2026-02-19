const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
db.settings({ 
  ignoreUndefinedProperties: true,
  databaseId: 'default'
});

async function updateMapType() {
  try {
    console.log('📝 Checking globalValue settings...');
    
    const docRef = db.collection('settings').doc('globalValue');
    const doc = await docRef.get();
    
    if (doc.exists) {
      console.log('📄 Current settings:', doc.data());
      
      // Change to OSM (free, no API key needed)
      await docRef.update({
        selectedMapType: 'osm'
      });
      
      console.log('✅ Changed selectedMapType to "osm"');
    } else {
      console.log('❌ globalValue document not found');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

updateMapType();
