import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Presentation shared by the screens that use the dashboard's blue palette.
class FitnessPage extends StatelessWidget {
  const FitnessPage({super.key, required this.title, required this.body});
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final blue = Colors.blue.shade700;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    );
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FD),
          contentPadding: const EdgeInsets.all(16),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: blue, width: 2),
          ),
          errorBorder: border.copyWith(
            borderSide: BorderSide(color: Colors.red.shade700),
          ),
          focusedErrorBorder: border.copyWith(
            borderSide: BorderSide(color: Colors.red.shade700, width: 2),
          ),
          errorMaxLines: 3,
          prefixIconColor: blue,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.blue.shade100,
            disabledForegroundColor: Colors.blue.shade900,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.blue.shade50),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(color: blue),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          centerTitle: true,
          foregroundColor: Colors.white,
          backgroundColor: blue,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          flexibleSpace: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [blue, Colors.blue.shade900]),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class FitnessCard extends StatelessWidget {
  const FitnessCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class FitnessState extends StatelessWidget {
  const FitnessState({
    super.key,
    required this.icon,
    required this.message,
    this.loading = false,
    this.error = false,
  });
  final IconData icon;
  final String message;
  final bool loading;
  final bool error;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FitnessCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: error ? Colors.red.shade50 : Colors.blue.shade50,
              child: Icon(
                icon,
                size: 32,
                color: error ? Colors.red.shade700 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    ),
  );
}
