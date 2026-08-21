import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.thumbnail,
    required this.images,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String thumbnail;
  final List<String> images;

  @override
  List<Object> get props => [
    id,
    title,
    description,
    price,
    rating,
    thumbnail,
    images,
  ];
}

class ProductPageEntity extends Equatable {
  const ProductPageEntity({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<ProductEntity> products;
  final int total;
  final int skip;
  final int limit;

  @override
  List<Object> get props => [products, total, skip, limit];
}
