import 'package:flutter_test/flutter_test.dart';
import 'package:student_buddy/core/utils/uuid_generator.dart';

void main() {
  group('UUID Generator Tests', () {
    test('Should generate a valid length UUID v4 string', () {
      final uuid = generateUuid();
      expect(uuid.length, equals(36));
    });

    test('Should match the RFC 4122 UUID v4 regex pattern', () {
      final uuid = generateUuid();
      final regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(regex.hasMatch(uuid), isTrue);
    });

    test('Should generate unique UUIDs on subsequent calls', () {
      final uuids = <String>{};
      for (int i = 0; i < 1000; i++) {
        final uuid = generateUuid();
        expect(uuids.contains(uuid), isFalse);
        uuids.add(uuid);
      }
      expect(uuids.length, equals(1000));
    });
  group('Model serialization/deserialization', () {
      test('UUID character positions check', () {
        final uuid = generateUuid();
        expect(uuid[8], equals('-'));
        expect(uuid[13], equals('-'));
        expect(uuid[18], equals('-'));
        expect(uuid[23], equals('-'));
        // Version must be 4
        expect(uuid[14], equals('4'));
        // Variant must be 8, 9, a, or b
        final variantChar = uuid[19].toLowerCase();
        expect(['8', '9', 'a', 'b'].contains(variantChar), isTrue);
      });
    });
  });
}
