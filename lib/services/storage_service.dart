import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadCardImage(int catId, Uint8List pngBytes) async {
    // Namespaceia por UID do guest para evitar colisão entre usuários
    // (o catId vem do SQLite local e não é único entre dispositivos).
    final uid = await AuthService().ensureSignedIn().then((u) => u.uid);
    final ref = _storage.ref('cards/$uid/cat_$catId.png');
    await ref.putData(
      pngBytes,
      SettableMetadata(contentType: 'image/png'),
    );
    return await ref.getDownloadURL();
  }
}
