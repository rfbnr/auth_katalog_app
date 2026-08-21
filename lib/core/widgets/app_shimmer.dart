import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: child,
  );
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    this.width = double.infinity,
    this.height = 16,
    this.radius = 4,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
