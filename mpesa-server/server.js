const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();
const admin = require('firebase-admin');

const app = express();

// Initialize Firebase Admin (requires FIREBASE_KEY env var pointing to json key file)
let db;
try {
    const keyFile = process.env.FIREBASE_KEY;
    if (keyFile) {
        const serviceAccount = require(keyFile);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        db = admin.firestore();
        console.log('✅ Firebase Admin initialized');
    } else {
        console.log('⚠️ FIREBASE_KEY not set - Firebase logging disabled');
    }
} catch (err) {
    console.log('⚠️ Firebase init error:', err.message);
}

// Configure CORS properly for all origins & allow Authorization header
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept', 'Authorization'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use(express.json());

// --- Firebase token verification middleware ---
async function verifyFirebaseToken(req, res, next) {
    if (!admin || !admin.auth) {
        return res.status(500).json({ error: 'Firebase Admin not initialized on server' });
    }

    const authHeader = req.headers.authorization || req.headers.Authorization;
    if (!authHeader || !authHeader.toString().startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Missing Authorization header with Bearer token' });
    }

    const idToken = authHeader.toString().split('Bearer ')[1];
    try {
        const decoded = await admin.auth().verifyIdToken(idToken);
        req.user = decoded; // attach decoded token
        next();
    } catch (err) {
        console.error('Token verification failed:', err.message || err);
        return res.status(401).json({ error: 'Invalid or expired ID token' });
    }
}

// Middleware to require admin role (reads Firestore users/{uid}.role)
async function requireAdmin(req, res, next) {
    try {
        if (!req.user || !req.user.uid) return res.status(401).json({ error: 'Unauthorized' });
        if (!db) return res.status(500).json({ error: 'Firestore not initialized' });

        const doc = await db.collection('users').doc(req.user.uid).get();
        const role = doc.exists ? (doc.data()?.role ?? '') : '';
        if (role !== 'admin') {
            return res.status(403).json({ error: 'Forbidden - admin role required' });
        }
        next();
    } catch (err) {
        console.error('Admin check failed:', err.message || err);
        return res.status(500).json({ error: 'Server error' });
    }
}

// Example admin-protected route prefix
app.get('/admin/status', verifyFirebaseToken, requireAdmin, (req, res) => {
    res.json({ ok: true, uid: req.user.uid, message: 'You are an admin' });
});

/* ==============================
   1️⃣ Generate Access Token
================================ */
async function getAccessToken() {
    const consumerKey = process.env.MPESA_CONSUMER_KEY.trim();
    const consumerSecret = process.env.MPESA_CONSUMER_SECRET.trim();

    const auth = Buffer
        .from(`${consumerKey}:${consumerSecret}`)
        .toString('base64');

    try {
        const response = await axios.get(
            'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
            {
                headers: {
                    Authorization: `Basic ${auth}`
                }
            }
        );

        return response.data.access_token;

    } catch (error) {
        console.error("❌ Token Error:", error.response?.data || error.message);
        throw error;
    }
}

/* ==============================
   2️⃣ STK Push Route
================================ */
app.post('/stkpush', async (req, res) => {

    console.log("📥 Payment request:", req.body);

    const { phone, amount } = req.body;

    if (!phone || !amount) {
        return res.status(400).json({ error: "Phone and amount required" });
    }

    try {
        const token = await getAccessToken();

        const timestamp = new Date()
            .toISOString()
            .replace(/[-:.TZ]/g, '')
            .slice(0, 14);

        const shortcode = process.env.MPESA_SHORTCODE;
        const passkey = process.env.MPESA_PASSKEY;

        const password = Buffer
            .from(shortcode + passkey + timestamp)
            .toString('base64');

        const response = await axios.post(
            'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
            {
                BusinessShortCode: shortcode,
                Password: password,
                Timestamp: timestamp,
                TransactionType: "CustomerPayBillOnline",
                Amount: Number(amount),
                PartyA: phone,
                PartyB: shortcode,
                PhoneNumber: phone,
                CallBackURL: process.env.CALLBACK_URL,
                AccountReference: "MyShop",
                TransactionDesc: "Payment"
            },
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        console.log("🟢 STK Response:", response.data);

        res.status(200).json(response.data);

        // Record STK push in Firestore as pending
        if (db) {
            try {
                const checkoutId = response.data.CheckoutRequestID;
                await db.collection('payments').doc(checkoutId).set({
                    phone: phone,
                    amount: Number(amount),
                    merchantRequestID: response.data.MerchantRequestID,
                    checkoutRequestID: checkoutId,
                    status: 'pending',
                    description: 'STK Push sent to customer',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
                console.log('✅ Payment record created:', checkoutId);
            } catch (err) {
                console.log('⚠️ Firestore write error:', err.message);
            }
        }

    } catch (error) {
        console.error("🔴 STK Error:", error.response?.data || error.message);
        res.status(500).json(error.response?.data || { error: "STK failed" });
    }
});

/* ==============================
   3️⃣ Callback
================================ */
app.post('/callback', (req, res) => {

    console.log("📩 Callback Received:");
    console.log(JSON.stringify(req.body, null, 2));

    // Update Firestore with callback result
    if (db) {
        try {
            const callback = req.body.Body?.stkCallback;
            if (callback) {
                const checkoutId = callback.CheckoutRequestID;
                const resultCode = callback.ResultCode;
                const resultDesc = callback.ResultDesc || '';

                let status = 'pending';
                if (resultCode === 0) {
                    status = 'completed';
                } else if (resultCode === 1032) {
                    status = 'cancelled';
                } else if (resultCode === 1037) {
                    status = 'no_response';
                } else {
                    status = 'error';
                }

                db.collection('payments').doc(checkoutId).update({
                    status: status,
                    resultCode: resultCode,
                    resultDesc: resultDesc,
                    callbackReceivedAt: admin.firestore.FieldValue.serverTimestamp(),
                }).catch(err => {
                    // If update fails, try set with merge
                    console.log('Update failed, trying set:', err.message);
                    db.collection('payments').doc(checkoutId).set({
                        status: status,
                        resultCode: resultCode,
                        resultDesc: resultDesc,
                        callbackReceivedAt: admin.firestore.FieldValue.serverTimestamp(),
                    }, { merge: true });
                });
                console.log('✅ Payment status updated:', checkoutId, '→', status);
            }
        } catch (err) {
            console.log('⚠️ Callback Firestore error:', err.message);
        }
    }

    res.status(200).send("OK");
});

/* ==============================
   4️⃣ Start Server
================================ */
const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
