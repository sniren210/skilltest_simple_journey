/// Model representing passport MRZ (Machine Readable Zone) data
class PassportMRZ {
  final String documentCode;
  final String issuingCountry;
  final String surname;
  final String givenNames;
  final String passportNumber;
  final String nationality;
  final String dateOfBirth;
  final String sex;
  final String expirationDate;
  final String personalNumber;
  final String rawMrzText;
  final DateTime scannedAt;

  const PassportMRZ({
    required this.documentCode,
    required this.issuingCountry,
    required this.surname,
    required this.givenNames,
    required this.passportNumber,
    required this.nationality,
    required this.dateOfBirth,
    required this.sex,
    required this.expirationDate,
    required this.personalNumber,
    required this.rawMrzText,
    required this.scannedAt,
  });

  /// Parses MRZ text from OCR result
  factory PassportMRZ.fromMrzText(String mrzText) {
    final lines = mrzText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.length < 2) {
      throw ArgumentError('Invalid MRZ format: Not enough lines');
    }

    try {
      // First line: Document code, Issuing country, Name
      final firstLine = lines[0].replaceAll(' ', '').padRight(44, '<');
      final documentCode = firstLine.substring(0, 2);
      final issuingCountry = firstLine.substring(2, 5);
      
      // Extract name section (everything after position 5)
      final nameSection = firstLine.substring(5).replaceAll('<', ' ').trim();
      final nameParts = nameSection.split(RegExp(r'\s{2,}')); // Split on multiple spaces
      
      final surname = nameParts.isNotEmpty ? nameParts[0].trim() : '';
      final givenNames = nameParts.length > 1 ? nameParts.sublist(1).join(' ').trim() : '';

      // Second line: Passport number, Check digit, Nationality, DOB, Check digit, Sex, Expiration, Check digit, Personal number, Check digits
      final secondLine = lines[1].replaceAll(' ', '').padRight(44, '<');
      
      // Extract fields with bounds checking
      final passportNumber = _extractField(secondLine, 0, 9);
      final nationality = _extractField(secondLine, 10, 13);
      final dateOfBirth = _formatDate(_extractField(secondLine, 13, 19));
      final sex = _extractField(secondLine, 20, 21);
      final expirationDate = _formatDate(_extractField(secondLine, 21, 27));
      final personalNumber = _extractField(secondLine, 28, 42);

      return PassportMRZ(
        documentCode: documentCode,
        issuingCountry: issuingCountry,
        surname: surname,
        givenNames: givenNames,
        passportNumber: passportNumber,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        sex: sex,
        expirationDate: expirationDate,
        personalNumber: personalNumber,
        rawMrzText: mrzText,
        scannedAt: DateTime.now(),
      );
    } catch (e) {
      // If parsing fails, try alternative parsing
      return _parseWithFallback(lines);
    }
  }

  /// Fallback parsing method for malformed MRZ
  static PassportMRZ _parseWithFallback(List<String> lines) {
    final firstLine = lines[0].replaceAll(' ', '').padRight(44, '<');
    final secondLine = lines[1].replaceAll(' ', '').padRight(44, '<');
    
    // Extract what we can
    return PassportMRZ(
      documentCode: firstLine.length >= 2 ? firstLine.substring(0, 2) : 'P<',
      issuingCountry: firstLine.length >= 5 ? firstLine.substring(2, 5) : 'UTO',
      surname: 'UNKNOWN',
      givenNames: 'UNKNOWN',
      passportNumber: _extractField(secondLine, 0, 9),
      nationality: firstLine.length >= 5 ? firstLine.substring(2, 5) : 'UTO',
      dateOfBirth: '000000',
      sex: 'X',
      expirationDate: '000000',
      personalNumber: '',
      rawMrzText: lines.join('\n'),
      scannedAt: DateTime.now(),
    );
  }

  static String _extractField(String line, int start, int end) {
    if (start >= line.length) return '';
    final actualEnd = end > line.length ? line.length : end;
    final actualStart = start < 0 ? 0 : start;
    
    if (actualStart >= actualEnd) return '';
    
    return line.substring(actualStart, actualEnd).replaceAll('<', '').trim();
  }

  static String _formatDate(String dateStr) {
    if (dateStr.length != 6) return dateStr;
    final year = int.tryParse(dateStr.substring(0, 2)) ?? 0;
    final month = dateStr.substring(2, 4);
    final day = dateStr.substring(4, 6);
    
    // Assume years 00-30 are 20xx, 31-99 are 19xx
    final fullYear = year <= 30 ? 2000 + year : 1900 + year;
    
    return '$day/$month/$fullYear';
  }

  Map<String, dynamic> toJson() {
    return {
      'documentCode': documentCode,
      'issuingCountry': issuingCountry,
      'surname': surname,
      'givenNames': givenNames,
      'passportNumber': passportNumber,
      'nationality': nationality,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
      'expirationDate': expirationDate,
      'personalNumber': personalNumber,
      'rawMrzText': rawMrzText,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory PassportMRZ.fromJson(Map<String, dynamic> json) {
    return PassportMRZ(
      documentCode: json['documentCode'] ?? '',
      issuingCountry: json['issuingCountry'] ?? '',
      surname: json['surname'] ?? '',
      givenNames: json['givenNames'] ?? '',
      passportNumber: json['passportNumber'] ?? '',
      nationality: json['nationality'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      sex: json['sex'] ?? '',
      expirationDate: json['expirationDate'] ?? '',
      personalNumber: json['personalNumber'] ?? '',
      rawMrzText: json['rawMrzText'] ?? '',
      scannedAt: DateTime.parse(json['scannedAt']),
    );
  }

  @override
  String toString() {
    return 'PassportMRZ(passportNumber: $passportNumber, surname: $surname, givenNames: $givenNames)';
  }

  // Additional getters for compatibility
  String get documentType => documentCode;
  String get countryCode => issuingCountry;
  
  // Simple validation based on basic checks
  bool get isValid {
    return passportNumber.isNotEmpty &&
           surname.isNotEmpty &&
           givenNames.isNotEmpty &&
           dateOfBirth.isNotEmpty &&
           expirationDate.isNotEmpty &&
           nationality.length == 3 &&
           issuingCountry.length == 3 &&
           sex.isNotEmpty;
  }
}
