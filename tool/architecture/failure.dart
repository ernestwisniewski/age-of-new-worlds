final class ArchitectureFailure implements Exception {
  const ArchitectureFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
