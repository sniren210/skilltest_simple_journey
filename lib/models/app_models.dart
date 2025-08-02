/// Model for NFC data read from documents
class NFCData {
  final String documentNumber;
  final String dateOfBirth;
  final String expirationDate;
  final Map<String, dynamic> dataGroups;
  final String? photoBase64;
  final bool isValid;
  final DateTime readAt;

  const NFCData({
    required this.documentNumber,
    required this.dateOfBirth,
    required this.expirationDate,
    required this.dataGroups,
    this.photoBase64,
    required this.isValid,
    required this.readAt,
  });

  factory NFCData.fromMap(Map<String, dynamic> data) {
    return NFCData(
      documentNumber: data['documentNumber'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      expirationDate: data['expirationDate'] ?? '',
      dataGroups: data['dataGroups'] ?? {},
      photoBase64: data['photoBase64'],
      isValid: data['isValid'] ?? false,
      readAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentNumber': documentNumber,
      'dateOfBirth': dateOfBirth,
      'expirationDate': expirationDate,
      'dataGroups': dataGroups,
      'photoBase64': photoBase64,
      'isValid': isValid,
      'readAt': readAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'NFCData(documentNumber: $documentNumber, isValid: $isValid)';
  }

  // Additional getters for compatibility
  DateTime get readTimestamp => readAt;
}

/// Model for biometric authentication results
class BiometricResult {
  final bool isAuthenticated;
  final String biometricType;
  final String? errorMessage;
  final DateTime authenticatedAt;

  const BiometricResult({
    required this.isAuthenticated,
    required this.biometricType,
    this.errorMessage,
    required this.authenticatedAt,
  });

  factory BiometricResult.success(String biometricType) {
    return BiometricResult(
      isAuthenticated: true,
      biometricType: biometricType,
      authenticatedAt: DateTime.now(),
    );
  }

  factory BiometricResult.failure(String biometricType, String errorMessage) {
    return BiometricResult(
      isAuthenticated: false,
      biometricType: biometricType,
      errorMessage: errorMessage,
      authenticatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAuthenticated': isAuthenticated,
      'biometricType': biometricType,
      'errorMessage': errorMessage,
      'authenticatedAt': authenticatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BiometricResult(isAuthenticated: $isAuthenticated, type: $biometricType)';
  }

  // Additional getters for compatibility
  bool get isSuccess => isAuthenticated;
  DateTime get timestamp => authenticatedAt;
}
