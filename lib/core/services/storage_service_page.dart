import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ServicePhotoUploadException implements Exception {
  const ServicePhotoUploadException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

String servicePhotoUploadMessage(String? code) {
  switch (code) {
    case 'unauthenticated':
    case 'unauthorized':
    case 'permission-denied':
      return 'Sesi upload foto berakhir. Silakan logout lalu login kembali.';
    case 'retry-limit-exceeded':
      return 'Upload foto melewati batas waktu. Periksa koneksi lalu coba lagi.';
    case 'quota-exceeded':
      return 'Penyimpanan foto sedang penuh. Silakan hubungi admin.';
    case 'canceled':
      return 'Upload foto dibatalkan.';
    default:
      return 'Gagal mengunggah foto. Periksa koneksi lalu coba lagi.';
  }
}

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
    final firebaseUser = fba.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != userId) {
      throw const ServicePhotoUploadException(
        'Sesi upload foto berakhir. Silakan logout lalu login kembali.',
        code: 'unauthenticated',
      );
    }
    if (!await imageFile.exists() || await imageFile.length() == 0) {
      throw const ServicePhotoUploadException(
        'File foto tidak valid. Silakan pilih foto kembali.',
        code: 'invalid-file',
      );
    }

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
    } on FirebaseException catch (e) {
      debugPrint('Service photo upload gagal (Firebase code: ${e.code}).');
      throw ServicePhotoUploadException(
        servicePhotoUploadMessage(e.code),
        code: e.code,
      );
    } on ServicePhotoUploadException {
      rethrow;
    } catch (e) {
      debugPrint('Service photo upload gagal (${e.runtimeType}).');
      throw ServicePhotoUploadException(servicePhotoUploadMessage(null));
    }
  }
}
