const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
db.settings({ 
  ignoreUndefinedProperties: true,
  databaseId: 'default'
});

async function updateGoogleMapsKey() {
  try {
    const apiKey = 'AIzaSyBJz_8okT-QCNB7o4TAvJeFGFqTGcf6z2o';
    
    // Update settings/global document with Google Maps API Key
    await db.collection('settings').doc('global').set({
      googleMapKey: apiKey
    }, { merge: true });
    
    console.log('✅ Google Maps API Key added to settings/global');
    
    // Also update settings/globalKey if it exists
    await db.collection('settings').doc('globalKey').set({
      googleMapKey: apiKey
    }, { merge: true });
    
    console.log('✅ Google Maps API Key added to settings/globalKey');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  process.exit(0);
}

updateGoogleMapsKey();
