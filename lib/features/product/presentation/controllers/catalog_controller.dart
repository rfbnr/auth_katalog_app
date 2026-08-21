import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../di/product_providers.dart';
import '../../domain/entities/product_entity.dart';
import '../states/catalog_state.dart';

final catalogSearchDebounceProvider = Provider<Duration>(
  (_) => const Duration(milliseconds: 400),
);

final catalogControllerProvider =
    AsyncNotifierProvider.autoDispose<CatalogController, CatalogState>(
      CatalogController.new,
      retry: (_, _) => null,
    );

class CatalogController extends AsyncNotifier<CatalogState> {
  static const pageSize = 10;

  Timer? _debounce;
  int _requestGeneration = 0;

  String _pendingQuery = '';

  @override
  Future<CatalogState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    final result = await _fetch(skip: 0, query: _pendingQuery);
    return result.fold(
      (failure) => throw failure,
      (page) => CatalogState(
        products: page.products,
        total: page.total,
        query: _pendingQuery,
      ),
    );
  }

  void search(String query) {
    _pendingQuery = query.trim();
    _debounce?.cancel();
    _debounce = Timer(ref.read(catalogSearchDebounceProvider), _reload);
  }

  Future<void> retry() {
    final current = state.value;
    if (current == null) return _reload();
    if (current.isPaginationFailure) return _loadMore(afterFailure: true);
    if (current.failure != null) return refresh();
    return _reload();
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    final current = state.value;
    if (current == null) return _reload();
    final generation = ++_requestGeneration;
    state = AsyncData(
      current.copyWith(
        isRefreshing: true,
        isPaginationFailure: false,
        failure: null,
      ),
    );
    final result = await _fetch(skip: 0, query: _pendingQuery);
    if (generation != _requestGeneration) return;
    result.fold(
      (failure) => state = AsyncData(
        current.copyWith(
          isRefreshing: false,
          isPaginationFailure: false,
          failure: failure,
        ),
      ),
      (page) => state = AsyncData(
        CatalogState(
          products: page.products,
          total: page.total,
          query: _pendingQuery,
        ),
      ),
    );
  }

  Future<void> loadMore() => _loadMore();

  Future<void> _loadMore({bool afterFailure = false}) async {
    final current = state.value;
    if (current == null ||
        current.isLoadingMore ||
        current.isRefreshing ||
        !current.hasMore ||
        (current.isPaginationFailure && !afterFailure)) {
      return;
    }
    final generation = _requestGeneration;
    state = AsyncData(
      current.copyWith(
        isLoadingMore: true,
        isPaginationFailure: false,
        failure: null,
      ),
    );
    final result = await _fetch(
      skip: current.products.length,
      query: current.query,
    );
    if (generation != _requestGeneration) return;
    result.fold(
      (failure) => state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          isPaginationFailure: true,
          failure: failure,
        ),
      ),
      (page) => state = AsyncData(
        current.copyWith(
          products: [...current.products, ...page.products],
          total: page.total,
          isLoadingMore: false,
          isPaginationFailure: false,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _reload() async {
    final generation = ++_requestGeneration;
    state = const AsyncLoading();
    final result = await _fetch(skip: 0, query: _pendingQuery);
    if (generation != _requestGeneration) return;
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (page) => state = AsyncData(
        CatalogState(
          products: page.products,
          total: page.total,
          query: _pendingQuery,
        ),
      ),
    );
  }

  Future<Either<Failure, ProductPageEntity>> _fetch({
    required int skip,
    required String query,
  }) =>
      ref.read(getProductsProvider)(limit: pageSize, skip: skip, query: query);
}
