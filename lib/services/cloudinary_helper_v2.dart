import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Enhanced Cloudinary helper with validation and error handling
class CloudinaryHelper {
  // ⚠️ REPLACE WITH YOUR CREDENTIALS ⚠️
  // Get these from: https://cloudinary.com/console/settings/api-keys
  static const String _cloudName = 'dagvje9af';      // YOUR_CLOUD_NAME
  static const String _uploadPreset = 'my_shop';   // YOUR_UNSIGNED_PRESET

  /// Check if Cloudinary is properly configured
  static bool get isConfigured {
    // Return false if using placeholder values
    return _cloudName.isNotEmpty && 
           _uploadPreset.isNotEmpty &&
           _cloudName != 'dagvje9af' &&
           _uploadPreset != 'my_shop';
  }

  /// Get validation error message if not configured
  static String? getConfigError() {
    if (_cloudName.isEmpty) return 'Cloud Name is empty';
    if (_uploadPreset.isEmpty) return 'Upload Preset is empty';
    if (_cloudName == 'dagvje9af') return 'Cloud Name is still placeholder (dagvje9af)';
    if (_uploadPreset == 'my_shop') return 'Upload Preset is still placeholder (my_shop)';
    return null;
  }

  /// Upload mobile file path to Cloudinary
  /// 
  /// Returns the secure HTTPS URL if successful, null on failure
  static Future<String?> uploadImage(String filePath) async {
    final configError = getConfigError();
    if (configError != null) {
      debugPrint('❌ Cloudinary config error: $configError');
      debugPrint('📖 See CLOUDINARY_SETUP.md for setup instructions');
      return null;
    }

    try {
      debugPrint('📤 Uploading image to Cloudinary...');
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload request timed out after 30 seconds');
        },
      );

      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      if (response.statusCode == 200 && data['secure_url'] != null) {
        final url = data['secure_url'] as String;
        debugPrint('✅ Upload successful: $url');
        return url;
      } else {
        debugPrint('❌ Cloudinary error (${response.statusCode}): $respStr');
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Exception during upload: $e');
      return null;
    }
  }

  /// Upload web image bytes to Cloudinary
  /// 
  /// Returns the secure HTTPS URL if successful, null on failure
  static Future<String?> uploadWebImage(Uint8List bytes) async {
    final configError = getConfigError();
    if (configError != null) {
      debugPrint('❌ Cloudinary config error: $configError');
      debugPrint('📖 See CLOUDINARY_SETUP.md for setup instructions');
      return null;
    }

    try {
      debugPrint('📤 Uploading web image to Cloudinary...');
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload request timed out after 30 seconds');
        },
      );

      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      if (response.statusCode == 200 && data['secure_url'] != null) {
        final url = data['secure_url'] as String;
        debugPrint('✅ Web upload successful: $url');
        return url;
      } else {
        debugPrint('❌ Cloudinary error (${response.statusCode}): $respStr');
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Exception during web upload: $e');
      return null;
    }
  }

  /// Optimize a Cloudinary URL for fast delivery
  /// Applies: width=400px, auto-fill, auto-crop, auto-quality
  static String optimizeUrl(String url) {
    if (url.contains('cloudinary.com')) {
      return url.replaceFirst('/upload/', '/upload/w_400,c_fill,g_auto,q_auto/');
    }
    return url;
  }
}
