const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();

// Configure CORS properly for all origins
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use(express.json());

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

    res.status(200).send("OK");
});

/* ==============================
   4️⃣ Start Server
================================ */
const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
