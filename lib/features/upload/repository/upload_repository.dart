import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class UploadRepository {
  UploadRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadVideo({
    required File file,
    required String userId,
    required String fileName,
    required void Function(int progress) onProgress,
  }) async {
    final path = 'videos/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref(path);
    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((snapshot) {
      final totalBytes = snapshot.totalBytes;
      if (totalBytes <= 0) return;
      final progress = ((snapshot.bytesTransferred / totalBytes) * 100).round();
      onProgress(progress.clamp(0, 100));
    });

    await uploadTask;
    return ref.getDownloadURL();
  }
}