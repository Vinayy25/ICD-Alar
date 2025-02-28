import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/screens/search_screen.dart';

class FloatingActionSearchButton extends StatelessWidget {
  final AnimationController fabAnimationController;
  final Animation<double> fabAnimation;
  const FloatingActionSearchButton(
      {super.key,
      required this.fabAnimationController,
      required this.fabAnimation});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      margin: const EdgeInsets.only(top: 40),
      child: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), // Make it perfectly round
        ),
        child: AnimatedBuilder(
          animation: fabAnimation,
          builder: (context, child) {
            // Wave-like animation effect when pressed
            return Transform.scale(
              scale: 1.0 +
                  fabAnimation.value *
                      0.2 *
                      (1 -
                          (fabAnimation.value - 0.5).abs() *
                              2), // Wave equation
              child: Icon(
                fabAnimationController.isDismissed ? Icons.search : Icons.close,
                size: 28,
              ),
            );
          },
        ),
        onPressed: () {
          if (fabAnimationController.isDismissed) {
            // Wave animation
            fabAnimationController.forward();

            // Add a slight delay before opening the search screen
            Future.delayed(const Duration(milliseconds: 50), () {
              // Show search screen with animation
              Navigator.of(context)
                  .push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SearchScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutQuint;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  )
                  .then((_) => fabAnimationController.reverse());
            });
          } else {
            fabAnimationController.reverse();
          }
        },
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 2000.ms, color: Colors.white30, size: 0.2),
    );
  }
}
