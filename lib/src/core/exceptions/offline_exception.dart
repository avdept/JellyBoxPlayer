class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => 'No connection to the server';
}
