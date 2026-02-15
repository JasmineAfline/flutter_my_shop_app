# Local M-Pesa STK Push Server

This is a standalone Node.js server for handling M-Pesa STK Push payment requests and callbacks. It avoids Firebase billing while providing full M-Pesa integration for your Flutter app.

## Quick Start

1. **Install dependencies:**
   ```bash
   cd mpesa-server
   npm install
   ```

2. **Start the server:**
   ```bash
   npm start
   ```
   The server will run on `http://localhost:3001`

3. **For development with auto-reload:**
   ```bash
   npm run dev
   ```

## API Endpoints

### POST `/stkpush`
Initiates an M-Pesa STK Push payment request.

**Request Body:**
```json
{
  "phone": "254700000000",
  "amount": 100
}
```

**Response (Success):**
```json
{
  "MerchantRequestID": "...",
  "CheckoutRequestID": "...",
  "ResponseCode": "0",
  "ResponseDescription": "Success. Request accepted for processing",
  "CustomerMessage": "Success. Request accepted for processing"
}
```

**Response (Error):**
```json
{
  "error": "STK Push failed",
  "details": "..."
}
```

### POST `/callback`
Receives M-Pesa payment confirmation callbacks from Safaricom sandbox.

**Note:** For production, you'll need to expose this endpoint via ngrok or a public server and update Safaricom's callback URL configuration.

### GET `/health`
Health check endpoint.

**Response:**
```json
{
  "status": "M-Pesa server is running"
}
```

## Configuration

Environment variables in `.env`:

- `MPESA_CONSUMER_KEY` — Your M-Pesa sandbox consumer key
- `MPESA_CONSUMER_SECRET` — Your M-Pesa sandbox consumer secret
- `MPESA_SHORTCODE` — Your M-Pesa business shortcode (e.g., 174379)
- `MPESA_PASSKEY` — Your M-Pesa passkey
- `PORT` — Server port (default: 3001)
- `CALLBACK_URL` — URL for M-Pesa to send payment status callbacks

## Integration with Flutter App

In your Flutter checkout screen, the app will POST to:
```
http://localhost:3001/stkpush
```

Update the endpoint in `lib/screens/checkout_screen.dart`:
```dart
static const String _stkPushEndpoint = 'http://localhost:3001/stkpush';
```

Or for production (deployed server):
```dart
static const String _stkPushEndpoint = 'https://your-deployed-server.com/stkpush';
```

## Testing

1. Start this server
2. Run your Flutter app
3. Navigate to Checkout
4. Enter a phone number (e.g., 254700000000)
5. Tap "Pay with M-Pesa"
6. You should see an M-Pesa STK prompt on the phone
7. Server logs will show the request and response

## Deployment

To deploy this server for production:

1. **Heroku:**
   ```bash
   heroku create your-app-name
   heroku config:set MPESA_CONSUMER_KEY="..." MPESA_CONSUMER_SECRET="..." MPESA_SHORTCODE="..." MPESA_PASSKEY="..."
   git push heroku main
   ```

2. **Railway.app, Render, or any Node hosting:**
   - Push the `mpesa-server` folder as a standalone repo
   - Set environment variables via the hosting platform's dashboard

3. **ngrok (for local testing with public callback):**
   ```bash
   npm start
   # In another terminal:
   ngrok http 3001
   # Update CALLBACK_URL in .env to your ngrok URL + /callback
   ```

## Troubleshooting

- **"M-Pesa credentials not configured"** — Check `.env` file has all required fields
- **"STK Push failed"** — Check Safaricom M-Pesa credentials are correct and account is active
- **Port 3001 already in use** — Change `PORT` in `.env` or kill the process: `lsof -ti:3001 | xargs kill -9`
