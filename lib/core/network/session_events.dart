import 'dart:async';

class SessionEvents {
  final _expiredController = StreamController<void>.broadcast();

  Stream<void> get expired => _expiredController.stream;

  void notifyExpired() => _expiredController.add(null);

  Future<void> dispose() => _expiredController.close();
}
