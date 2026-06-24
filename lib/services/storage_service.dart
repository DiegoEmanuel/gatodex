import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadCardImage(int catId, Uint8List pngBytes) async {
    final ref = _storage.ref('cards/cat_$catId.png');
    await ref.putData(
      pngBytes,
      SettableMetadata(contentType: 'image/png'),
    );
    return await ref.getDownloadURL();
  }
}
