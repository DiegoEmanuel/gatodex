import 'package:firebase_auth/firebase_auth.dart';

/// Gerencia o "perfil guest" do usuário via autenticação anônima do Firebase.
///
/// Cada dispositivo ganha um UID estável (persistido pelo SDK), o que permite
/// namespacear os uploads no Storage e, no futuro, fazer upgrade para um login
/// real (Google/Apple/e-mail) com `linkWithCredential`, preservando os dados.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// UID do guest atual (null se ainda não autenticou).
  String? get uid => _auth.currentUser?.uid;

  /// Garante que existe uma sessão (anônima por padrão) e devolve o usuário.
  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }
}
