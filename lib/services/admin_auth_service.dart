import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<bool> isAuthorizedAdmin(User user) async {
    final email = (user.email ?? '').trim().toLowerCase();

    if (await _documentExists('admin_users', user.uid)) return true;
    if (await _documentExists('admins', user.uid)) return true;

    if (email.isNotEmpty) {
      if (await _documentExists('admin_users', email)) return true;
      if (await _documentExists('admins', email)) return true;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) return false;

    return _hasAdminFlag(userData);
  }

  Future<bool> _documentExists(String collection, String docId) async {
    if (docId.trim().isEmpty) return false;
    final doc = await _firestore.collection(collection).doc(docId).get();
    return doc.exists;
  }

  bool _hasAdminFlag(Map<String, dynamic> data) {
    final isAdmin = data['isAdmin'] == true || data['is_admin'] == true;
    if (isAdmin) return true;

    final role = _readText(data, 'role').toLowerCase();
    final accountType = _readText(data, 'accountType').toLowerCase();
    final userType = _readText(data, 'userType').toLowerCase();

    return role == 'admin' ||
        accountType == 'admin' ||
        userType == 'admin';
  }

  String _readText(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String) return value.trim();
    return '';
  }
}
