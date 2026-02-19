const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'goride-a9d8f.firebasestorage.app'
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

async function uploadServiceAccount() {
  try {
    console.log('📤 Uploading service account JSON to Firebase Storage...');
    
    // Read the service account file
    const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
    
    // Upload to Firebase Storage
    const destination = 'notification/service-account.json';
    
    await bucket.upload(serviceAccountPath, {
      destination: destination,
      metadata: {
        contentType: 'application/json',
      },
    });
    
    // Make the file publicly accessible
    const file = bucket.file(destination);
    await file.makePublic();
    
    // Get the public URL - use the new Firebase Storage domain
    const publicUrl = `https://storage.googleapis.com/goride-a9d8f.firebasestorage.app/${destination}`;
    
    console.log('✅ File uploaded successfully!');
    console.log('🔗 Public URL:', publicUrl);
    
    // Update Firestore settings
    console.log('\n📝 Updating Firestore notification settings...');
    
    await db.collection('settings').doc('notification_setting').set({
      isEnabled: true,
      senderId: 'goride-a9d8f',
      jsonNotificationFileURL: publicUrl,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
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

uploadServiceAccount();
