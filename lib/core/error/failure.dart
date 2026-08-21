import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Sesi tidak valid. Silakan masuk kembali.',
  ]);
}

final class BadRequestFailure extends Failure {
  const BadRequestFailure([super.message = 'Permintaan tidak valid.']);
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Anda tidak memiliki akses.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan.']);
}

final class NoInternetFailure extends Failure {
  const NoInternetFailure([
    super.message = 'Tidak ada koneksi internet. Periksa koneksi Anda.',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server sedang bermasalah. Coba lagi.']);
}

final class StorageFailure extends Failure {
  const StorageFailure([
    super.message = 'Penyimpanan aman tidak dapat diakses.',
  ]);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Terjadi kesalahan. Coba lagi.']);
}
