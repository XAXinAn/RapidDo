import 'package:flutter/material.dart';

// Custom RectTween for a smoother Hero animation curve
class CustomRectTween extends RectTween {
  CustomRectTween({super.begin, super.end});

  @override
  Rect? lerp(double t) {
    // Apply a curve to the tween's progress
    final double curvedT = Curves.easeInOut.transform(t);
    return Rect.lerp(begin, end, curvedT);
  }
}
