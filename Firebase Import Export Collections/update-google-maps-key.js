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

async function updateGoogleMapsKey() {
  try {
    const newApiKey = 'AIzaSyAb3p2UEDZuLOPokFUTwpHEkpORrayXig0';
    
    console.log('📝 Updating Google Maps API Key in Firestore...');
    
    // Update in constant settings
    const constantRef = db.collection('settings').doc('constant');
    const constantDoc = await constantRef.get();
    
    if (constantDoc.exists) {
      console.log('📄 Current constant settings:', constantDoc.data());
      await constantRef.update({
        googleMapKey: newApiKey
      });
      console.log('✅ Updated constant.googleMapKey');
    }
    
    // Update in globalValue settings
    const globalRef = db.collection('settings').doc('globalValue');
    const globalDoc = await globalRef.get();
    
    if (globalDoc.exists) {
      console.log('📄 Current globalValue settings:', globalDoc.data());
      await globalRef.update({
        googleMapKey: newApiKey
      });
      console.log('✅ Updated globalValue.googleMapKey');
    }
    
    console.log('\n🎉 Google Maps API Key updated successfully!');
    console.log('New API Key:', newApiKey);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

updateGoogleMapsKey();
