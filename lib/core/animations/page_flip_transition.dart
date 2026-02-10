import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PageFlipTransition extends PageRouteBuilder {
  final Widget page;

  PageFlipTransition({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final rotateAnim = Tween<double>(begin: math.pi / 2, end: 0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          );

          return AnimatedBuilder(
            animation: rotateAnim,
            builder: (context, child) {
              // We use a 3D transform to simulate the flip
              return Transform(
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateY(rotateAnim.value),
                alignment: Alignment.centerLeft,
                child: child,
              );
            },
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      );
}

/// A premium custom transition for GoRouter that uses the PageFlipTransition
/// effect with enhanced shadow, lighting, and depth cues.
class PageFlipTransitionPage<T> extends CustomTransitionPage<T> {
  PageFlipTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Entering page rotation (book opening from right)
           final openingTransform = Tween<double>(
             begin: math.pi / 2,
             end: 0,
           ).animate(
             CurvedAnimation(
               parent: animation,
               curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
             ),
           );

           // Exiting page rotation (book closing to left)
           final closingTransform = Tween<double>(
             begin: 0,
             end: -math.pi / 2,
           ).animate(
             CurvedAnimation(
               parent: secondaryAnimation,
               curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
             ),
           );

           // Shadow intensity follows the flip midpoint
           final shadowOpacity = Tween<double>(
             begin: 0.0,
             end: 0.4,
           ).animate(CurvedAnimation(
             parent: animation,
             curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
             reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeOut),
           ));

           return AnimatedBuilder(
             animation: Listenable.merge([animation, secondaryAnimation]),
             builder: (context, child) {
               return Stack(
                 children: [
                   // Exiting page with dimming overlay
                   if (secondaryAnimation.value > 0)
                     Transform(
                       transform: Matrix4.identity()
                         ..setEntry(3, 2, 0.001)
                         ..rotateY(closingTransform.value),
                       alignment: Alignment.centerLeft,
                       child: Stack(
                         children: [
                           Container(color: Colors.black12),
                           // Dimming overlay on the old page
                           Positioned.fill(
                             child: Container(
                               color: Colors.black.withValues(
                                 alpha: secondaryAnimation.value * 0.15,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),

                   // Page edge shadow (cast by the flipping page)
                   if (animation.value > 0.01 && animation.value < 0.99)
                     Positioned(
                       left: 0,
                       top: 0,
                       bottom: 0,
                       width: 24,
                       child: Container(
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             begin: Alignment.centerLeft,
                             end: Alignment.centerRight,
                             colors: [
                               Colors.black.withValues(
                                 alpha: shadowOpacity.value * 0.6,
                               ),
                               Colors.transparent,
                             ],
                           ),
                         ),
                       ),
                     ),

                   // Entering page with lighting gradient overlay
                   Transform(
                     transform: Matrix4.identity()
                       ..setEntry(3, 2, 0.001)
                       ..rotateY(openingTransform.value),
                     alignment: Alignment.centerLeft,
                     child: Stack(
                       children: [
                         child!,
                         // Lighting gradient: simulates light on the page surface
                         if (animation.value < 0.95)
                           Positioned.fill(
                             child: IgnorePointer(
                               child: Container(
                                 decoration: BoxDecoration(
                                   gradient: LinearGradient(
                                     begin: Alignment.centerLeft,
                                     end: Alignment.centerRight,
                                     colors: [
                                       Colors.white.withValues(
                                         alpha: (1 - animation.value) * 0.12,
                                       ),
                                       Colors.black.withValues(
                                         alpha: (1 - animation.value) * 0.06,
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                             ),
                           ),
                       ],
                     ),
                   ),
                 ],
               );
             },
             child: child,
           );
         },
         transitionDuration: const Duration(milliseconds: 800),
       );
}
