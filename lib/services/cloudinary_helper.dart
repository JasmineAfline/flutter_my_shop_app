import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryHelper {
  // Replace these with your actual details from your Cloudinary Dashboard
  static final String _cloudName = 'your_cloud_name'; 
  static final String _uploadPreset = 'your_unsigned_preset'; 

  static final cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

  static Future<String?> uploadImage(String filePath) async {
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