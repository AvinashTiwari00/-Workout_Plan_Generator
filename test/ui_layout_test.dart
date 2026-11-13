import 'package:college_project/screens/login_screen.dart';
import 'package:college_project/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final signup in [false, true]) {
    testWidgets(
      '${signup ? 'Signup' : 'Login'} fits narrow screen with keyboard and validation',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: signup ? const SignupScreen() : const LoginScreen(),
          ),
        );
        expect(tester.takeException(), isNull);
        final form = tester.state<FormState>(find.byType(Form));
        expect(form.validate(), isFalse);
        await tester.pump();
        final button = find.byType(ElevatedButton);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
