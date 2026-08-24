/// Base failure class for fpdart Either<Failure, T> error handling conventions across repository boundaries.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Server or API failure (e.g. HTTP 5xx or network connection failure)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Local storage / Cache failure
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Parsing or format failure
class ParsingFailure extends Failure {
  const ParsingFailure(super.message, {super.code});
}

/// Hardware / Permission failure (e.g. Camera permission denied)
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

/// Generic unexpected failure fallback
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'An unexpected error occurred', String? code])
      : super(message, code: code);
}

