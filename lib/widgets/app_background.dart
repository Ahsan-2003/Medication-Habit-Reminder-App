import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
              : [
                  const Color(0xFFE0F2F1), // Soft teal 50
                  Colors.white,
                ],
        ),
      ),
      child: child,
    );
  }
}
