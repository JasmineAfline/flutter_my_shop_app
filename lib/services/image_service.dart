import 'package:cloudinary/cloudinary.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageService {
  // Initialize Cloudinary with your credentials
  // Replace these with your actual Cloudinary credentials
  static final cloudinary = Cloudinary.signedConfig(
    apiKey: 'YOUR_API_KEY',
    apiSecret: 'YOUR_API_SECRET',
    cloudName: 'YOUR_CLOUD_NAME',
  );

  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Pick an image from camera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Upload image to Cloudinary
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      CloudinaryResponse response;
      
      if (kIsWeb) {
        // For web platform
        final bytes = await imageFile.readAsBytes();
        response = await cloudinary.upload(
          fileBytes: bytes,
          resourceType: CloudinaryResourceType.image,
          folder: 'user_profiles',
          fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        // For mobile platforms
        response = await cloudinary.upload(
          file: imageFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'user_profiles',
          fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (response.isSuccessful) {
        return response.secureUrl;
      } else {
        print('Upload failed: ${response.error}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Delete image from Cloudinary
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract public ID from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final publicIdWithExtension = pathSegments.sublist(pathSegments.indexOf('user_profiles')).join('/');
      final publicId = publicIdWithExtension.split('.').first;

      final response = await cloudinary.destroy(publicId);
      return response.isSuccessful;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Show image source selection dialog
  static Future<XFile?> showImageSourceDialog({
    required Function() onCameraSelected,
    required Function() onGallerySelected,
  }) async {
    // This will be called from the UI
    return null;
  }
}
