require('dotenv').config();
const functions = require("firebase-functions");
const axios = require("axios");
const base64 = require("base-64");

// Load M-Pesa credentials from environment variables
const consumerKey = process.env.MPESA_CONSUMER_KEY;
const consumerSecret = process.env.MPESA_CONSUMER_SECRET;
const shortcode = process.env.MPESA_SHORTCODE;
const passkey = process.env.MPESA_PASSKEY;
const callbackUrl = process.env.CALLBACK_URL || "https://my-shop-e305a.firebaseapp.com/callback";

// Log configuration status (without exposing secrets)
console.log("M-Pesa Configuration:");
console.log("- Consumer Key exists:", !!consumerKey);
console.log("- Consumer Secret exists:", !!consumerSecret);
console.log("- Shortcode:", shortcode);
console.log("- Passkey exists:", !!passkey);
console.log("- Callback URL:", callbackUrl);

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
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  console.log("STK Push Request received:", req.body);
  
  const { phone, amount } = req.body;

  if (!phone || !amount) {
    console.error("Missing phone or amount");
    return res.status(400).send({ error: "phone and amount are required" });
  }

  console.log("Credentials check - Key exists:", !!consumerKey, "Secret exists:", !!consumerSecret);
  console.log("Shortcode:", shortcode, "Passkey:", passkey ? "exists" : "missing");

  try {
    const token = await getAccessToken();
    console.log("Got access token successfully");
    
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
      CallBackURL: callbackUrl,
      AccountReference: "MyShop",
      TransactionDesc: "Payment for goods",
    };

    console.log("Sending STK request to Safaricom...");
    const response = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      stkRequest,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    console.log("STK Push response:", response.data);
    res.status(200).send(response.data);
  } catch (error) {
    console.error("STK Push Error:", error.response?.data || error);
    res.status(500).send({ 
      error: "STK Push failed", 
      details: error.response?.data || error.message,
      stack: error.stack 
    });
  }
});

// M-Pesa Callback Function
exports.stkPushCallback = functions.https.onRequest((req, res) => {
  console.log("M-Pesa Callback Received:", req.body);
  // TODO: Save payment confirmation to your database
  res.status(200).send("OK");
});
