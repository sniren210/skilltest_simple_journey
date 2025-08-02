import 'package:flutter_test/flutter_test.dart';
import '../lib/services/ocr_service.dart';

void main() {
  group('OCR MRZ Extraction Tests', () {
    test('Real-world passport MRZ extraction', () {
      const sampleText = '''
UTOPIA
Type/ Type
P
Sumame Nom
ERIKSSON
Glven names/ Prénoms
ANNA MARIA
Nationality/ Nationalité
UTOPIAN
Country code/ Code du pays
UTO
Date of Birth Date de naissance
12 AUGIAOUT 74
Sex/ Sexe
F
Date of issue/ Date de delivrance
16 APR/AVR 07
Passport Numberl N de passep
L898902C3
Place of birth/ Lieu de naissance
ZENITH
Date of expiry/ Date d'expiration
15APRIAVR 12
Personal No/ N° personnel
ZE 184226 B
Authority/ Autorité
PASSPORT OFFICE
Holder's signature Signature du titulaire
Cnna Mlaria Exikss an
P<UTOERIKS S ON<<ANNA<MARIA<<<
L898902C36UTO7408122F1204159ZE184226B<<<<<10
''';

      final result = OCRService.testExtractMRZ(sampleText);
      
      expect(result, isNotNull, reason: 'Should extract MRZ from sample text');
      
      if (result != null) {
        // Verify all extracted data matches expected values
        expect(result.surname, equals('ERIKSSON'), reason: 'Surname should be correctly extracted');
        expect(result.givenNames, equals('ANNA MARIA'), reason: 'Given names should be correctly extracted');
        expect(result.passportNumber, equals('L898902C3'), reason: 'Passport number should be correctly extracted');
        expect(result.nationality, equals('UTO'), reason: 'Nationality should be correctly extracted');
        expect(result.sex, equals('F'), reason: 'Sex should be correctly extracted');
        expect(result.personalNumber, equals('ZE184226B'), reason: 'Personal number should be correctly extracted');
        expect(result.documentType, contains('P'), reason: 'Document type should contain P for passport');
        expect(result.countryCode, equals('UTO'), reason: 'Country code should be correctly extracted');
        expect(result.isValid, isTrue, reason: 'Extracted MRZ should be valid');
        
        // Verify dates are properly formatted
        expect(result.dateOfBirth, contains('/'), reason: 'Date of birth should be formatted');
        expect(result.expirationDate, contains('/'), reason: 'Expiration date should be formatted');
      }
    });

    test('Empty text handling', () {
      final result = OCRService.testExtractMRZ('');
      expect(result, isNull, reason: 'Should return null for empty text');
    });

    test('Invalid text handling', () {
      const invalidText = 'This is just random text with no MRZ data';
      final result = OCRService.testExtractMRZ(invalidText);
      expect(result, isNull, reason: 'Should return null for text without MRZ');
    });
  });
}
