import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedLottieIcon extends StatelessWidget {
  final String lottieAsset;
  final double width;
  final double height;
  final bool repeat;

  const AnimatedLottieIcon({
    super.key,
    required this.lottieAsset,
    this.width = 60,
    this.height = 60,
    this.repeat = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Lottie.asset(
        lottieAsset,
        repeat: repeat,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent.withValues(alpha: 0.5),
            size: width * 0.6,
          );
        },
      ),
    );
  }
}
