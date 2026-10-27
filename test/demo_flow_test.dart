import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:defame/core/demo.dart';
import 'package:defame/features/feed.dart';

Map<String, dynamic> draft(String request, {bool anonymous = true}) => {
  'request_id': request,
  'title': 'A story from my day',
  'body': 'We had a thoughtful conversation over coffee.',
  'subject_name': '',
  'is_anonymous': anonymous,
  'category': 'Friendship',
  'kind': 'post',
  'attested': true,
};
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DemoStore.active.value = false;
    await DemoStore.start();
  });
  test('public profile excludes anonymous posts while private manager retains them', () async {
    await DemoStore.call('publish', draft('anon'));
    await DemoStore.call('publish', draft('public', anonymous: false));
    final profile = await DemoStore.call('profile', {});
    expect((profile['profile']['posts'] as List).length, 1);
    expect(profile['profile']['posts'][0]['is_anonymous'], false);
    final mine = await DemoStore.call('feed', {'mine': true, 'page': 0});
    expect((mine['posts'] as List).length, 2);
    await DemoStore.start();
    final persisted = await DemoStore.call('feed', {'mine': true, 'page': 0});
    expect((persisted['posts'] as List).length, 2);
  });
  test(
    'retrying submission is idempotent and reactions can switch and clear',
    () async {
      final first = await DemoStore.call('publish', draft('retry'));
      final second = await DemoStore.call('publish', draft('retry'));
      expect(first['id'], second['id']);
      await DemoStore.call('react', {'post_id': first['id'], 'value': 'like'});
      final switchVote = await DemoStore.call('react', {
        'post_id': first['id'],
        'value': 'dislike',
      });
      expect(switchVote['likes'], 0);
      expect(switchVote['dislikes'], 1);
      final clear = await DemoStore.call('react', {
        'post_id': first['id'],
        'value': null,
      });
      expect(clear['dislikes'], 0);
    },
  );
  test(
    'username collision is case insensitive and group membership persists',
    () async {
      expect(
        () => DemoStore.call('edit_profile', {'username': 'AlEx_StOrIeS'}),
        throwsException,
      );
      await DemoStore.call('join', {'community_id': 'group-2', 'join': true});
      await DemoStore.start();
      final groups = await DemoStore.call('communities', {'joined_only': true});
      expect((groups['communities'] as List).length, 2);
    },
  );
  testWidgets('walkthrough can navigate groups, profile and create a story', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FeedShell()));
    await tester.pumpAndSettle();
    expect(find.textContaining('LOCAL DEMO'), findsOneWidget);
    expect(
      find.text('A first date that turned into a cooking competition'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.groups_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Philadelphia stories'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_circle_outline).last);
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.enterText(field('Title'), 'A new anonymous story');
    await tester.ensureVisible(field('What happened?'));
    await tester.enterText(
      field('What happened?'),
      'I met up with my friends and had a wonderful afternoon.',
    );
    final consent = find.byType(CheckboxListTile);
    await tester.scrollUntilVisible(
      consent,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: consent, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Share Experience');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('A new anonymous story'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person_outline).last);
    await tester.pumpAndSettle();
    expect(find.text('@your_demo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No public posts yet.'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('No public posts yet.'), findsOneWidget);
    expect(find.text('A new anonymous story'), findsNothing);
  });
}
