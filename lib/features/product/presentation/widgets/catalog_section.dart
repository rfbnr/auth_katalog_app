import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../controllers/catalog_controller.dart';
import '../states/catalog_state.dart';
import 'catalog_error_view.dart';
import 'catalog_grid.dart';
import 'catalog_shimmer.dart';
import 'product_card.dart';

class CatalogSection extends ConsumerStatefulWidget {
  const CatalogSection({required this.onAdditionalRefresh, super.key});

  final Future<void> Function() onAdditionalRefresh;

  @override
  ConsumerState<CatalogSection> createState() => _CatalogSectionState();
}

class _CatalogSectionState extends ConsumerState<CatalogSection> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 400) {
      ref.read(catalogControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(catalogControllerProvider.notifier).refresh(),
      widget.onAdditionalRefresh(),
    ]);
  }

  void _search(String query) =>
      ref.read(catalogControllerProvider.notifier).search(query);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CatalogSearchField(controller: _searchController, onChanged: _search),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final catalog = ref.watch(catalogControllerProvider);
              final notifier = ref.read(catalogControllerProvider.notifier);

              return catalog.when(
                loading: () => const CatalogShimmer(),
                error: (error, _) => RefreshIndicator(
                  onRefresh: _refresh,
                  child: CatalogErrorView(
                    error: error,
                    onRetry: notifier.retry,
                  ),
                ),
                data: (state) => _CatalogDataView(
                  state: state,
                  scrollController: _scrollController,
                  onRefresh: _refresh,
                  onProductTap: (id) =>
                      context.push(AppRoutes.productDetail(id)),
                  onRetry: notifier.retry,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CatalogSearchField extends StatelessWidget {
  const _CatalogSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SearchBar(
        controller: controller,
        hintText: 'Cari produk...',
        leading: const Icon(Icons.search),
        trailing: [
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _CatalogDataView extends StatelessWidget {
  const _CatalogDataView({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
    required this.onProductTap,
    required this.onRetry,
  });

  final CatalogState state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onProductTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.products.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.inventory_2_outlined, size: 56),
            SizedBox(height: 16),
            Text('Produk tidak ditemukan.', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: CatalogGrid.padding,
                sliver: SliverGrid.builder(
                  gridDelegate: CatalogGrid.delegateFor(
                    context,
                    constraints.maxWidth,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => onProductTap(product.id),
                    );
                  },
                ),
              ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (state.failure case final failure?)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      children: [
                        Text(failure.message, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: onRetry,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
