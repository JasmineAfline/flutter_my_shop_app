import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Replace with your actual credentials
  static final cloudinary = CloudinaryPublic(
    'your_cloud_name', 
    'your_preset_name', 
    cache: false
  );

  static bool get _isConfigured {
    final name = 'your_cloud_name'.toLowerCase();
    final preset = 'your_preset_name'.toLowerCase();
    return !name.contains('your') && !preset.contains('your');
  }

  static Future<String?> uploadImage() async {
    if (!_isConfigured) {
      print('CloudinaryService: credentials are not configured. Set your cloud name and preset in cloudinary_service.dart');
      return null;
    }

    final ImagePicker picker = ImagePicker();

    // 1. Pick the image from gallery
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        // 2. Upload to Cloudinary
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path, 
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        
        // 3. Return the secure URL
        return response.secureUrl;
      } catch (e) {
        print("Cloudinary Upload Error: $e");
        return null;
      }
    }
    return null;
  }
}