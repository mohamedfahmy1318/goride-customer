const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// ============================================================================
// Bankily B-PAY Configuration
// ============================================================================
const BANKILY_CONFIG = {
    // Test environment
    test: {
        baseUrl: 'https://ebankily-tst.appspot.com',
        username: 'ETS_EWE',
        password: '12345',
        clientId: 'ebankily',
    },
    // Production environment (update when going live)
    production: {
        baseUrl: 'https://ebankily.appspot.com',
        username: '', // Production credentials
        password: '', // Production credentials
        clientId: 'ebankily',
    },
};

// Set to 'test' or 'production'
const BANKILY_ENV = 'test';
const config = BANKILY_CONFIG[BANKILY_ENV];

// Token cache (in-memory, refreshed as needed)
let tokenCache = {
    accessToken: null,
    refreshToken: null,
    expiresAt: 0,
    refreshExpiresAt: 0,
};

// ============================================================================
// Helper: Get Bankily Access Token
// ============================================================================
async function getBankilyToken() {
    const now = Date.now();

    // If token is still valid (with 30s buffer), return cached
    if (tokenCache.accessToken && tokenCache.expiresAt > now + 30000) {
        return tokenCache.accessToken;
    }

    // If refresh token is still valid, use it
    if (tokenCache.refreshToken && tokenCache.refreshExpiresAt > now + 30000) {
        try {
            const token = await refreshBankilyToken(tokenCache.refreshToken);
            return token;
        } catch (e) {
            console.log('Refresh token failed, getting new token:', e.message);
        }
    }

    // Get a new token
    try {
        const params = new URLSearchParams();
        params.append('grant_type', 'password');
        params.append('username', config.username);
        params.append('password', config.password);
        params.append('client_id', config.clientId);

        const response = await axios.post(
            `${config.baseUrl}/authentification`,
            params.toString(),
            {
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                timeout: 15000,
            }
        );

        tokenCache = {
            accessToken: response.data.access_token,
            refreshToken: response.data.refresh_token,
            expiresAt: now + (response.data.expires_in * 1000),
            refreshExpiresAt: now + (response.data.refresh_expires_in * 1000),
        };

        console.log('Bankily: New token obtained successfully');
        return tokenCache.accessToken;
    } catch (error) {
        console.error('Bankily: Failed to get token:', error.response?.data || error.message);
        throw new Error('Failed to authenticate with Bankily');
    }
}

// ============================================================================
// Helper: Refresh Bankily Token
// ============================================================================
async function refreshBankilyToken(refreshToken) {
    const now = Date.now();

    const params = new URLSearchParams();
    params.append('grant_type', 'refresh_token');
    params.append('client_id', config.clientId);
    params.append('refresh_token', refreshToken);

    const response = await axios.post(
        `${config.baseUrl}/authentification`,
        params.toString(),
        {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            timeout: 15000,
        }
    );

    tokenCache = {
        accessToken: response.data.access_token,
        refreshToken: response.data.refresh_token,
        expiresAt: now + (response.data.expires_in * 1000),
        refreshExpiresAt: now + (response.data.refresh_expires_in * 1000),
    };

    console.log('Bankily: Token refreshed successfully');
    return tokenCache.accessToken;
}

// ============================================================================
// Cloud Function: Bankily Payment
// ============================================================================
// Called from the Flutter app to process a Bankily B-PAY payment
// Required data: { clientPhone, passcode, amount, operationId, language }
exports.bankilyPayment = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Must be authenticated.');
    }

    const { clientPhone, passcode, amount, operationId, language } = request.data;

    // Validate required fields
    if (!clientPhone || !passcode || !amount || !operationId) {
        throw new HttpsError('invalid-argument',
            'Missing required fields: clientPhone, passcode, amount, operationId');
    }

    try {
        // Get access token
        const accessToken = await getBankilyToken();

        // Call Bankily Payment API
        const response = await axios.post(
            `${config.baseUrl}/payment`,
            {
                clientPhone: clientPhone.toString(),
                passcode: passcode.toString(),
                amount: amount.toString(),
                language: language || 'ar',
                operationId: operationId.toString(),
            },
            {
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json',
                },
                timeout: 50000,
            }
        );

        const result = response.data;
        console.log(`Bankily Payment Response for ${operationId}:`, JSON.stringify(result));

        // Save transaction to Firestore
        const db = admin.firestore();
        await db.collection('bankily_transactions').doc(operationId).set({
            operationId: operationId,
            clientPhone: clientPhone,
            amount: amount.toString(),
            language: language || 'ar',
            errorCode: result.errorCode || '',
            errorMessage: result.errorMessage || '',
            transactionId: result.transactionId || '',
            status: result.errorCode === '0' ? 'success' : 'failed',
            userId: request.auth.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            environment: BANKILY_ENV,
        }, { merge: true });

        return {
            success: result.errorCode === '0',
            errorCode: result.errorCode,
            errorMessage: result.errorMessage,
            transactionId: result.transactionId,
        };
    } catch (error) {
        console.error('Bankily Payment Error:', error.response?.data || error.message);

        // Save failed transaction
        try {
            const db = admin.firestore();
            await db.collection('bankily_transactions').doc(operationId).set({
                operationId: operationId,
                clientPhone: clientPhone,
                amount: amount.toString(),
                status: 'error',
                error: error.response?.data?.errorMessage || error.message,
                userId: request.auth.uid,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                environment: BANKILY_ENV,
            }, { merge: true });
        } catch (e) {
            console.error('Failed to save error transaction:', e);
        }

        // Provide specific error message for timeout
        const isTimeout = error.code === 'ECONNABORTED' || error.message?.includes('timeout');
        const errorMsg = isTimeout
            ? 'خادم بنكيلي لا يستجيب. حاول مرة أخرى لاحقاً.'
            : (error.response?.data?.errorMessage || 'فشل في عملية الدفع. حاول مرة أخرى.');

        throw new HttpsError('internal', errorMsg);
    }
});

// ============================================================================
// Cloud Function: Check Bankily Transaction
// ============================================================================
// Called from the Flutter app to check the status of a transaction
// Required data: { operationId }
exports.bankilyCheckTransaction = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Must be authenticated.');
    }

    const { operationId } = request.data;

    if (!operationId) {
        throw new HttpsError('invalid-argument', 'Missing operationId');
    }

    try {
        // Get access token
        const accessToken = await getBankilyToken();

        // Call Bankily Check Transaction API
        const response = await axios.post(
            `${config.baseUrl}/checkTransaction`,
            { operationId: operationId.toString() },
            {
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json',
                },
                timeout: 15000,
            }
        );

        const result = response.data;
        console.log(`Bankily Check Transaction for ${operationId}:`, JSON.stringify(result));

        // Map status codes
        // TS = transaction success, TF = transaction failed, TA = transaction pending
        let statusText = 'unknown';
        if (result.status === 'TS') statusText = 'success';
        else if (result.status === 'TF') statusText = 'failed';
        else if (result.status === 'TA') statusText = 'pending';

        // Update transaction in Firestore
        const db = admin.firestore();
        await db.collection('bankily_transactions').doc(operationId).update({
            checkStatus: statusText,
            checkErrorCode: result.errorCode || '',
            checkErrorMessage: result.errorMessage || '',
            checkTransactionId: result.transactionId || '',
            checkedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
            success: result.errorCode === '0' && result.status === 'TS',
            errorCode: result.errorCode,
            errorMessage: result.errorMessage,
            transactionId: result.transactionId,
            status: statusText,
            rawStatus: result.status,
        };
    } catch (error) {
        console.error('Bankily Check Transaction Error:', error.response?.data || error.message);
        throw new HttpsError('internal',
            error.response?.data?.errorMessage || 'Failed to check transaction.');
    }
});

// ============================================================================
// Cloud Function: Send Push Notification (Server-side)
// ============================================================================
// Sends FCM notifications securely from the server
// Required data: { token, title, body, payload, dataOnly? }
// For multiple tokens: { tokens, title, body, payload }
exports.sendNotification = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Must be authenticated.');
    }

    const { token, tokens, title, body, payload, dataOnly } = request.data;

    if (!title || !body) {
        throw new HttpsError('invalid-argument', 'Missing title or body');
    }

    const targetTokens = tokens || (token ? [token] : []);
    if (targetTokens.length === 0) {
        throw new HttpsError('invalid-argument', 'Missing token or tokens');
    }

    const results = [];
    for (const fcmToken of targetTokens) {
        if (!fcmToken || fcmToken.trim() === '') continue;
        try {
            const message = {
                token: fcmToken,
                data: payload || {},
                android: { priority: 'high' },
            };
            if (dataOnly) {
                message.data.title = title;
                message.data.body = body;
            } else {
                message.notification = { title, body };
            }
            const response = await admin.messaging().send(message);
            results.push({ token: fcmToken, success: true, messageId: response });
        } catch (error) {
            console.error(`Failed to send to ${fcmToken}:`, error.message);
            results.push({ token: fcmToken, success: false, error: error.message });
        }
    }

    return { success: true, results };
});

// ============================================================================
// Delete Auth User Function
// ============================================================================
exports.deleteUser = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError(
            'unauthenticated',
            'The function must be called while authenticated.'
        );
    }
    try {
        await admin.auth().deleteUser(request.data.uid);
        return { result: 'User successfully deleted' };
    } catch (error) {
        console.error('Error deleting user:', error);
        throw new HttpsError('internal', error.message);
    }
});