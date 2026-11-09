sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  T valueOrThrow() => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>(:final failure) => throw failure,
  };

  R when<R>({required R Function(T value) ok, required R Function(Failure failure) err}) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final failure) => err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message, [this.cause]);
  final Object? cause;
}

final class SyncFailure extends Failure {
  const SyncFailure(super.message, [this.cause]);
  final Object? cause;
}

final class DeviceFailure extends Failure {
  const DeviceFailure(super.message, [this.cause]);
  final Object? cause;
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, [this.cause]);
  final Object? cause;
}
