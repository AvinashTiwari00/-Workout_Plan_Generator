import '../repositories/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:college_project/models/user_models.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  UserAccount? _account;
  UserProfile? _profile;

  User? get user => _user;
  UserAccount? get account => _account;
  UserProfile? get profile => _profile;

  void setSession({
    required User user,
    required UserAccount account,
    required UserProfile profile,
  }) {
    _user = user;
    _account = account;
    _profile = profile;
    notifyListeners();
  }

  void setAccount(UserAccount account, {UserProfile? profile}) {
    _user = null;
    _account = account;
    _profile = profile;
    notifyListeners();
  }

  void setUser(User user, {UserProfile? profile}) {
    _user = user;
    _profile = profile;
    notifyListeners();
  }

  Future<void> refresh() async {
    final id = _account?.id;
    if (id == null) return;
    final user = await UserRepository().loadDashboardUser(id);
    if (_account?.id != id || user == null) return;
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _account = null;
    _profile = null;
    notifyListeners();
  }
}
