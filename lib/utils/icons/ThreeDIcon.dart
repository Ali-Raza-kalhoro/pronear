import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThreeDIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double rotationX;
  final double rotationY;

  const ThreeDIcon({
    super.key,
    required this.icon,
    this.size = 36,
    this.color = Colors.white,
    this.rotationX = 0.2,
    this.rotationY = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(rotationX)
        ..rotateY(rotationY),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}

// Usage:
