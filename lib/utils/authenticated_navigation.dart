import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/user_provider.dart';
import '../repositories/user_repository.dart';
import '../screens/dashboard_screen.dart';
import '../screens/user_input_screen.dart';
import 'session_store.dart';

/// Single post-authentication destination for signup, login and session restore.
Future<void> openAuthenticatedHome(
  BuildContext context,
  UserAccount account,
) async {
  final users = UserRepository();
  await SessionStore().saveUserId(account.id);
  final profile = await users.getProfile(account.id);
  final complete = await users.hasCompleteProfile(account.id);
  final user = complete ? await users.loadDashboardUser(account.id) : null;
  if (!context.mounted) return;
  final provider = context.read<UserProvider>();
  if (user != null && profile != null) {
    provider.setSession(user: user, account: account, profile: profile);
  } else {
    provider.setAccount(account, profile: profile);
  }
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => user != null && profile != null
          ? DashboardScreen(user: user)
          : const UserInputScreen(),
    ),
    (_) => false,
  );
}
