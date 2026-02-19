const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://goride-a9d8f-default-rtdb.firebaseio.com'
});

const db = admin.firestore();
db.settings({ 
  ignoreUndefinedProperties: true,
  databaseId: 'default'
});

async function updateNotificationSettings() {
  try {
    const publicUrl = 'https://storage.googleapis.com/goride-a9d8f.firebasestorage.app/notification/service-account.json';
    
    console.log('📝 Checking if notification_setting exists...');
    
    const docRef = db.collection('settings').doc('notification_setting');
    const doc = await docRef.get();
    
    if (doc.exists) {
      console.log('📄 Document exists, updating...');
      console.log('Current data:', doc.data());
    } else {
      console.log('📄 Document does not exist, creating...');
    }
    
    // Use set with merge to create or update
    await docRef.set({
      senderId: 'goride-a9d8f',
      serviceJson: publicUrl,
    }, { merge: true });
    
    console.log('✅ Firestore updated successfully!');
    console.log('\n🎉 Notification setup complete!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Service Account URL:', publicUrl);
    console.log('Sender ID: goride-a9d8f');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

updateNotificationSettings();
