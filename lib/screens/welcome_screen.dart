import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌆 Full Hero Image
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              "https://images.pexels.com/photos/6390236/pexels-photo-6390236.jpeg",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.blueGrey.shade900,
                child: const Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // 🖤 Dark Glass Overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ⭐ Center Content with Responsiveness
          LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth > 600;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: isWeb
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        if (isWeb)
                          const Spacer(), // Push content more to center on web
                        // ⚡ Main Title
                        Text(
                          "TRANSFORM\nYOUR BODY",
                          textAlign: isWeb ? TextAlign.center : TextAlign.start,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔥 Subtitle & Value Prop
                        Text(
                          "Your fitness journey starts here.",
                          textAlign: isWeb ? TextAlign.center : TextAlign.start,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Personalized workout plans based on your body goal and fitness level.",
                          textAlign: isWeb ? TextAlign.center : TextAlign.start,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // 💠 CTA Button
                        SizedBox(
                          width: isWeb ? 300 : double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.zero,
                              elevation: 8,
                              shadowColor: Colors.blue.withOpacity(0.4),
                            ),
                            child: const Text(
                              "Get Started",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isWeb ? 40 : 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
