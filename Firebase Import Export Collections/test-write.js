const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Use the correct database name
const db = admin.firestore();
db.settings({ 
  ignoreUndefinedProperties: true,
  databaseId: 'default'
});

async function testWrite() {
  try {
    console.log('Testing Firestore write...');
    
    // Try to write a simple test document
    const testDoc = await db.collection('test').doc('test-doc').set({
      message: 'Hello from import script!',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Write successful!');
    
    // Read it back
    const doc = await db.collection('test').doc('test-doc').get();
    console.log('✅ Read successful:', doc.data());
    
    // Delete test doc
    await db.collection('test').doc('test-doc').delete();
    console.log('✅ Delete successful!');
    
    console.log('\n✅ Firestore is working correctly!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Full error:', error);
  }
  
  process.exit(0);
}

testWrite();
