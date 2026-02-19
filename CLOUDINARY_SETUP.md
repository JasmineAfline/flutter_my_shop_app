# Cloudinary Image Upload Setup Guide

## Overview
The app now uploads product images to Cloudinary before storing the secure URL in Firestore. This ensures:
- Centralized image hosting
- Optimized image delivery
- Secure image management
- Firestore stores only the URL (lightweight)

## Step 1: Create a Cloudinary Account
1. Go to https://cloudinary.com/users/register/free
2. Sign up with your email or GitHub/Google account
3. Verify your email

## Step 2: Get Your Credentials
1. Log in to Cloudinary Dashboard
2. Go to **Settings > API Keys**
3. Note your:
   - **Cloud Name** (e.g., `dagvje9af`) — used in API calls
   - **API Key** (for server-side operations)
   - **API Secret** (keep private)

## Step 3: Create an Upload Preset
1. Go to **Settings > Upload**
2. Click **Add upload preset**
3. Configure:
   - **Name**: `ecommerce` (or any name)
   - **Signing Mode**: `Unsigned` (for client-side uploads from Flutter)
   - **Folder**: `my_shop/products` (optional, for organization)
   - Click **Save**

4. Note the preset name (e.g., `ecommerce`)

## Step 4: Update Flutter App Configuration
Edit `lib/screens/admin/screens/add_product_screen.dart` and update the `CloudinaryHelper` class:

```dart
class CloudinaryHelper {
  static const String _cloudName = 'YOUR_CLOUD_NAME';      // Replace with your cloud name
  static const String _uploadPreset = 'YOUR_PRESET_NAME';  // Replace with your preset
  // ... rest of code
}
```

Example:
```dart
class CloudinaryHelper {
  static const String _cloudName = 'dagvje9af';
  static const String _uploadPreset = 'ecommerce';
}
```

## Step 5: Configure Firestore Security Rules (Already Done ✅)
Your Firestore rules already restrict product writes to admins only. When an admin uploads a product:
1. Image is uploaded to Cloudinary via client-side unsigned upload
2. Cloudinary returns a secure URL
3. Admin confirms and saves product with the Cloudinary URL to Firestore
4. Firestore rules validate that only admins can write to `/products`

## Image Upload Flow

### Admin Side (Add/Edit Product)
```
1. Admin picks image from gallery
2. Admin clicks "Upload Image" button
3. Image is sent to Cloudinary (client-side, unsigned)
4. Cloudinary returns secure URL (HTTPS)
5. URL is displayed in preview
6. Admin fills in product details and clicks "UPLOAD TO STORE"
7. Product is saved to Firestore with Cloudinary URL
```

### Customer Side (View Product)
```
1. App fetches product from Firestore
2. Product document contains imageUrl (Cloudinary URL)
3. App displays image via Image.network(imageUrl)
4. Cloudinary serves optimized image
```

## Troubleshooting

### "Failed to upload image" or "Upload error"
- **Check Cloudinary credentials** in `add_product_screen.dart`
- **Verify upload preset is unsigned**: Settings > Upload > Your Preset > Signing Mode = Unsigned
- **Check console logs** for detailed error messages
- **Test in Flutter DevTools** console for Cloudinary API errors

### Image not showing in product list
- **Verify Firestore has imageUrl field** for the product
- **Check if URL is valid** (should start with `https://`)
- **Test URL in browser** — should load the image

### 401 Unauthorized Error
- **Ensure preset is NOT signed** (should be unsigned for client uploads)
- **Verify Cloud Name is correct** in `_cloudName`
- **Double-check preset name** — must match exactly

## Firestore Structure

Products are now stored as:
```json
{
  "title": "Example Product",
  "price": 5999,
  "description": "Product description",
  "imageUrl": "https://res.cloudinary.com/YOUR_CLOUD_NAME/image/upload/...",
  "category": "Electronics",
  "createdAt": "2026-02-19T...",
  "active": true
}
```

## Optional: Optimize Images

Add query parameters to Cloudinary URLs for optimization:
```dart
String optimizeUrl(String url) {
  if (url.contains('cloudinary.com')) {
    return url.replaceFirst('/upload/', '/upload/w_400,c_fill,g_auto,q_auto/');
  }
  return url;
}
```

This resizes to 400px width, fills the area, auto-crops, and optimizes quality.

## Summary
- ✅ Images are uploaded to Cloudinary (client-side, no server storage needed)
- ✅ Firestore stores only the secure URL
- ✅ Admin role required to add products (enforced by Firestore rules)
- ✅ All images are served from Cloudinary CDN (fast and scalable)
