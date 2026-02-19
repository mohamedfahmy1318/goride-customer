const admin = require('firebase-admin');

// Initialize Firebase Admin with service account
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateRegionCode() {
  try {
    const docRef = db.collection('settings').doc('globalValue');
    
    await docRef.update({
      regionCode: 'all',
      regionCountry: 'All'
    });
    
    console.log('✅ Successfully updated regionCode to "all" and regionCountry to "All"');
    console.log('البحث الآن سيعمل على مستوى العالم!');
    
    // Verify the update
    const doc = await docRef.get();
    console.log('\nCurrent values:');
    console.log('regionCode:', doc.data().regionCode);
    console.log('regionCountry:', doc.data().regionCountry);
    
  } catch (error) {
    console.error('Error updating document:', error);
  }
  
  process.exit(0);
}

updateRegionCode();
