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

/// A custom transition for GoRouter that uses the PageFlipTransition effect.
class PageFlipTransitionPage<T> extends CustomTransitionPage<T> {
  PageFlipTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Animation for the entering page
           final openingTransform = Tween<double>(
             begin: math.pi / 2,
             end: 0,
           ).animate(
             CurvedAnimation(
               parent: animation,
               curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
             ),
           );

           // Animation for the exiting page (secondaryAnimation)
           final closingTransform = Tween<double>(
             begin: 0,
             end: -math.pi / 2,
           ).animate(
             CurvedAnimation(
               parent: secondaryAnimation,
               curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
             ),
           );

           return AnimatedBuilder(
             animation: animation,
             builder: (context, child) {
               return Stack(
                 children: [
                   // Handle exiting page (rotation to the left)
                   if (secondaryAnimation.value > 0)
                     Transform(
                       transform:
                           Matrix4.identity()
                             ..setEntry(3, 2, 0.001)
                             ..rotateY(closingTransform.value),
                       alignment: Alignment.centerLeft,
                       child: Container(
                         color: Colors.black12,
                       ), 
                     ),

                   // Handle entering page (rotation from the right)
                   Transform(
                     transform:
                         Matrix4.identity()
                           ..setEntry(3, 2, 0.001)
                           ..rotateY(openingTransform.value),
                     alignment: Alignment.centerLeft,
                     child: child,
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
