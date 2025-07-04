import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk memilih gambar dari galeri
  Future<File?> pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Fungsi untuk mengunggah file dan mendapatkan URL download
  Future<String> uploadServicePhoto(
    File imageFile,
    String serviceId,
    String userId,
  ) async {
    try {
      // Buat path yang unik untuk setiap gambar
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child(
        'service_photos/$userId/$serviceId/$fileName',
      );

      // Unggah file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Dapatkan URL download
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Gagal mengunggah foto.");
    }
  }
}
