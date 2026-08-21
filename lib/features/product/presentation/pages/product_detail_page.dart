import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../domain/entities/product_entity.dart';
import '../controllers/product_detail_controller.dart';
import '../widgets/product_detail_shimmer.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productDetailControllerProvider(productId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: product.when(
        loading: () => const ProductDetailShimmer(),
        error: (error, _) => _DetailError(
          message: failureMessage(
            error,
            fallback: 'Detail produk gagal dimuat.',
          ),
          onRetry: () => ref
              .read(productDetailControllerProvider(productId).notifier)
              .retry(),
        ),
        data: (item) => _ProductDetail(item),
      ),
    );
  }
}

class _ProductDetail extends StatelessWidget {
  const _ProductDetail(this.product);

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final images = product.images.isEmpty
        ? <String>[product.thumbnail]
        : product.images;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            itemCount: images.length,
            itemBuilder: (_, index) => CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.contain,
              placeholder: (_, _) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, size: 64),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.rupiah(product.price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_rounded, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(product.rating.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(product.description),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
