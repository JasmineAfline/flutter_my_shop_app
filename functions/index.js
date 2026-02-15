require('dotenv').config();
const functions = require("firebase-functions");
const axios = require("axios");
const base64 = require("base-64");

// Load M-Pesa credentials from Firebase config or environment variables (fallback)
let consumerKey;
let consumerSecret;
let shortcode;
let passkey;
try {
  const cfg = functions.config();
  consumerKey = cfg?.mpesa?.consumer_key;
  consumerSecret = cfg?.mpesa?.consumer_secret;
  shortcode = cfg?.mpesa?.shortcode;
  passkey = cfg?.mpesa?.passkey;
} catch (e) {
  // functions.config() may not be available in firebase-functions v7+. Use env vars.
  consumerKey = process.env.MPESA_CONSUMER_KEY;
  consumerSecret = process.env.MPESA_CONSUMER_SECRET;
  shortcode = process.env.MPESA_SHORTCODE;
  passkey = process.env.MPESA_PASSKEY;
}

// Generate OAuth token for M-Pesa API
async function getAccessToken() {
  const auth = base64.encode(`${consumerKey}:${consumerSecret}`);
  try {
    const response = await axios.get(
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      {
        headers: { Authorization: `Basic ${auth}` },
      }
    );
    return response.data.access_token;
  } catch (error) {
    console.error("Error getting M-Pesa token:", error.response?.data || error);
    throw error;
  }
}

// Lipa Na M-Pesa Online Payment Function
exports.stkPush = functions.https.onRequest(async (req, res) => {
  const { phone, amount } = req.body;

  if (!phone || !amount) {
    return res.status(400).send({ error: "phone and amount are required" });
  }

  try {
    const token = await getAccessToken();
    const timestamp = new Date()
      .toISOString()
      .replace(/[^0-9]/g, "")
      .slice(0, 14);

    const password = base64.encode(shortcode + passkey + timestamp);

    const stkRequest = {
      BusinessShortCode: shortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: amount,
      PartyA: phone,
      PartyB: shortcode,
      PhoneNumber: phone,
      CallBackURL: "https://e57a-38-226-202-118.ngrok-free.app/stkPushCallback",
      AccountReference: "MyShop",
      TransactionDesc: "Payment for goods",
    };

    const response = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      stkRequest,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    res.status(200).send(response.data);
  } catch (error) {
    console.error("STK Push Error:", error.response?.data || error);
    res.status(500).send({ error: "STK Push failed" });
  }
});

// M-Pesa Callback Function
exports.stkPushCallback = functions.https.onRequest((req, res) => {
  console.log("M-Pesa Callback Received:", req.body);
  // TODO: Save payment confirmation to your database
  res.status(200).send("OK");
});
