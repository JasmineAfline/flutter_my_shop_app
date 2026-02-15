const express = require('express');
const cors = require('cors');
const axios = require('axios');
const base64 = require('base-64');
require('dotenv').config();

const app = express();

// Enable CORS for all routes (allows Flutter web app to call this server)
app.use(cors());
app.use(express.json());

// M-Pesa Configuration
const CONSUMER_KEY = process.env.MPESA_CONSUMER_KEY || '';
const CONSUMER_SECRET = process.env.MPESA_CONSUMER_SECRET || '';
const SHORTCODE = process.env.MPESA_SHORTCODE || '';
const PASSKEY = process.env.MPESA_PASSKEY || '';
const CALLBACK_URL = process.env.CALLBACK_URL || 'http://localhost:3001/mpesa/callback';

// Generate OAuth token for M-Pesa API
async function getAccessToken() {
  if (!CONSUMER_KEY || !CONSUMER_SECRET) {
    throw new Error('M-Pesa credentials not configured in .env');
  }

  const auth = base64.encode(`${CONSUMER_KEY}:${CONSUMER_SECRET}`);
  try {
    const response = await axios.get(
      'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
      {
        headers: { Authorization: `Basic ${auth}` },
      }
    );
    return response.data.access_token;
  } catch (error) {
    console.error('Error getting M-Pesa token:', error.response?.data || error.message);
    throw error;
  }
}

// STK Push endpoint
app.post('/stkpush', async (req, res) => {
  const { phone, amount } = req.body;

  if (!phone || !amount) {
    return res.status(400).json({ error: 'phone and amount are required' });
  }

  try {
    const token = await getAccessToken();
    const timestamp = new Date()
      .toISOString()
      .replace(/[^0-9]/g, '')
      .slice(0, 14);

    const password = base64.encode(SHORTCODE + PASSKEY + timestamp);

    const stkRequest = {
      BusinessShortCode: SHORTCODE,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phone,
      PartyB: SHORTCODE,
      PhoneNumber: phone,
      CallBackURL: CALLBACK_URL,
      AccountReference: 'MyShop',
      TransactionDesc: 'Payment for goods',
    };

    console.log('Sending STK Push request:', stkRequest);

    const response = await axios.post(
      'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
      stkRequest,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    console.log('STK Push response:', response.data);
    res.status(200).json(response.data);
  } catch (error) {
    console.error('STK Push Error:', error.response?.data || error.message);
    res.status(500).json({ 
      error: 'STK Push failed',
      details: error.response?.data || error.message
    });
  }
});

// M-Pesa Callback endpoint
app.post('/callback', (req, res) => {
  console.log('M-Pesa Callback Received:', req.body);
  // TODO: Save payment confirmation to your database (Firestore)
  res.status(200).json({ success: true });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'M-Pesa server is running' });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`M-Pesa server running on port ${PORT}`);
  console.log(`STK Push endpoint: http://localhost:${PORT}/stkpush`);
  console.log(`Callback URL: ${CALLBACK_URL}`);
});
