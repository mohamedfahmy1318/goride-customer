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

async function setupNotificationSettings() {
  try {
    // Firebase Project ID
    const projectId = 'goride-a9d8f';
    
    // IMPORTANT: You need to upload your serviceAccountKey.json to Firebase Storage
    // and get the public URL, OR host it somewhere accessible
    // For now, we'll set a placeholder - you need to replace this with actual URL
    const serviceJsonUrl = 'YOUR_SERVICE_ACCOUNT_JSON_URL';
    
    // Update settings/notification_setting document
    await db.collection('settings').doc('notification_setting').set({
      senderId: projectId,
      serviceJson: serviceJsonUrl,
      enabled: true
    }, { merge: true });
    
    console.log('✅ Notification settings added to settings/notification_setting');
    console.log('');
    console.log('⚠️  IMPORTANT: You need to:');
    console.log('1. Upload your serviceAccountKey.json to Firebase Storage');
    console.log('2. Make it publicly readable');
    console.log('3. Update the serviceJson URL in Firestore');
    console.log('');
    console.log('📋 Project ID:', projectId);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  process.exit(0);
}

setupNotificationSettings();
