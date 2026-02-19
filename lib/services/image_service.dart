import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  // Initialize Cloudinary with your credentials
  // Replace these with your actual Cloudinary credentials
  static final cloudinary = CloudinaryPublic(
    'YOUR_CLOUD_NAME',
    'YOUR_UPLOAD_PRESET',
    cache: false,
  );

  static bool get _isConfigured {
    final name = 'YOUR_CLOUD_NAME'.toLowerCase();
    final preset = 'YOUR_UPLOAD_PRESET'.toLowerCase();
    return !name.contains('your') && !preset.contains('your');
  }

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
    if (!_isConfigured) {
      print('ImageService: Cloudinary credentials not configured. Update image_service.dart with your cloud name and upload preset.');
      return null;
    }

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'user_profiles',
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
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
