import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1440,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Image picking error: $e');
      return null;
    }
  }

  Future<List<File>?> pickMultipleImages() async {
    try {
      final List<XFile> images =
          await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1440);
      return images?.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      debugPrint('Image picking error: $e');
      return null;
    }
  }

  Future<String?> uploadProductImage(File image, String productId) async {
    try {
      // Compress image before upload
      final compressedImage = await _compressImage(image);

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'product_${productId}_$timestamp.jpg';

      // Create reference
      final ref = _storage.ref().child('product_images/$productId/$filename');

      // Configure upload metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': 'mobile_app',
          'productId': productId,
          'timestamp': timestamp.toString(),
        },
      );

      // Start the upload
      final uploadTask = ref.putFile(compressedImage, metadata);

      // Track upload progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        debugPrint('Upload progress: '
            '${taskSnapshot.bytesTransferred}/${taskSnapshot.totalBytes} '
            '(${taskSnapshot.state.toString()})');
      });

      // Wait for upload to complete
      final taskSnapshot = await uploadTask;

      // Verify upload completed successfully
      if (taskSnapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${taskSnapshot.state}');
      }

      // Get download URL
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      debugPrint('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error uploading image: $e');
      rethrow;
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final targetPath = '$path/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 80,
        minWidth: 800,
        minHeight: 800,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return file;
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('Image deleted successfully: $imageUrl');
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        debugPrint('Error deleting image: ${e.code} - ${e.message}');
        rethrow;
      }
      debugPrint('Image already deleted, ignoring error');
    } catch (e) {
      debugPrint('Unexpected error deleting image: $e');
      rethrow;
    }
  }

  Future<bool> checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
