import 'package:shared_preferences/shared_preferences.dart';
import '../Entites/utilisateur.dart';
import 'database_helper.dart';

class SessionService {
  static const _kUserId = 'session_user_id';

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> persistUser(Utilisateur user) async {
    if (user.id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kUserId, user.id!);
  }

  Future<Utilisateur?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kUserId);
    if (id == null) return null;
    try {
      final user = await _db.getUtilisateurById(id);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
  }

  Future<bool> isLoggedIn() async => (await getLoggedInUser()) != null;
}
