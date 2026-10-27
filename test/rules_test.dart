import 'package:flutter_test/flutter_test.dart';
import 'package:defame/core/rules.dart';

void main() {
  test('expiration hides a story at the exact visibility deadline', () {
    final now = DateTime.utc(2026, 10, 26);
    expect(
      DraftRules.isVisible({
        'moderation_status': 'approved',
        'expires_at': now.toIso8601String(),
      }, now),
      false,
    );
    expect(
      DraftRules.isVisible({
        'moderation_status': 'approved',
        'expires_at': now.add(const Duration(seconds: 1)).toIso8601String(),
      }, now),
      true,
    );
    expect(DraftRules.isVisible({'moderation_status': 'pending'}, now), false);
  });
  test(
    'private contact information and full subject names need correction',
    () {
      expect(
        DraftRules.validate('My story', 'My number is 215-555-1234.', ''),
        isNotNull,
      );
      expect(
        DraftRules.validate(
          'My story',
          'This was my firsthand experience.',
          'David Patterson',
        ),
        isNotNull,
      );
      expect(
        DraftRules.validate(
          'My story',
          'This was my firsthand experience.',
          'David P.',
        ),
        isNull,
      );
    },
  );
  test('dislikes affect popular score', () {
    expect(DraftRules.score(8, 7), lessThan(DraftRules.score(5, 1)));
  });
}
