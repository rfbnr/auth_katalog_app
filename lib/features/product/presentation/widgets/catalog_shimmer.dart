import 'package:flutter/material.dart';

import '../../../../core/widgets/app_shimmer.dart';
import 'catalog_grid.dart';

class CatalogShimmer extends StatelessWidget {
  const CatalogShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: CatalogGrid.padding,
          gridDelegate: CatalogGrid.delegateFor(context, constraints.maxWidth),
          itemCount: CatalogGrid.columnsFor(constraints.maxWidth) * 3,
          itemBuilder: (_, _) => const AppShimmer(
            child: Card(child: ColoredBox(color: Colors.white)),
          ),
        );
      },
    );
  }
}
