class DttException implements Exception {
  final String message;
  DttException(this.message);
}

class DttValidationError extends DttException {
  final String field;
  final String message;
  DttValidationError(this.field, this.message) : super(message);
}
