import 'package:flutter/material.dart';

import '../../../../core/widgets/app_shimmer.dart';

class ProductDetailShimmer extends StatelessWidget {
  const ProductDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: 320, radius: 0),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 220, height: 28),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerBox(width: 140, height: 28),
                      Spacer(),
                      ShimmerBox(width: 56, height: 20),
                    ],
                  ),
                  SizedBox(height: 24),
                  ShimmerBox(width: 100, height: 20),
                  SizedBox(height: 12),
                  ShimmerBox(height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 200, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
