/// Custom exceptions for the app

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException([this.message = 'Network error occurred. Please check your connection.']);
  
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  
  ServerException([this.message = 'Server error occurred. Please try again later.']);
  
  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  
  TimeoutException([this.message = 'Request timed out. Please try again.']);
  
  @override
  String toString() => message;
}

class InvalidFileException implements Exception {
  final String message;
  
  InvalidFileException([this.message = 'Invalid file. Please select a valid APK file.']);
  
  @override
  String toString() => message;
}

class InvalidInputException implements Exception {
  final String message;
  
  InvalidInputException([this.message = 'Invalid input. Please check and try again.']);
  
  @override
  String toString() => message;
}
