import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryHelper {
  // Replace these with your actual details from your Cloudinary Dashboard
  static final String _cloudName = 'dagvje9af';
  static final String _uploadPreset = 'my_shop';

  static bool get _isConfigured {
    final name = _cloudName.toLowerCase();
    final preset = _uploadPreset.toLowerCase();
    return !name.contains('your') && !preset.contains('your');
  }

  static final cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

  static Future<String?> uploadImage(String filePath) async {
    if (!_isConfigured) {
      print('Cloudinary not configured. Replace _cloudName and _uploadPreset in cloudinary_helper.dart with your Cloudinary details.');
      return null;
    }

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
          folder: 'products', // This creates a 'products' folder in Cloudinary
        ),
      );

      return response.secureUrl; // This is the 'https://...' link
    } catch (e) {
      print("Cloudinary Error: $e");
      return null;
    }
  }
}