import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rules.dart';

/// Isolated device data for a walkthrough. Never touches Supabase or verifies ID.
class DemoStore {
  static final active = ValueNotifier(false);
  static const userId = 'demo-owner';
  static Map<String, dynamic> state = {};
  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();
  static Future<void> start() async {
    final saved = (await SharedPreferences.getInstance()).getString(
      'defame_demo_v1',
    );
    try {
      state = saved == null ? {} : jsonDecode(saved);
    } catch (_) {
      state = {};
    }
    if (state.isEmpty) {
      final now = DateTime.now().toUtc();
      state = {
        'profile': {
          'id': userId,
          'username': 'your_demo',
          'display_name': 'Your De-Fame preview',
          'bio': 'Try the stories, groups and profile flows.',
          'is_moderator': true,
        },
        'posts':
            [
                  {
                    'id': 'sample-1',
                    'title':
                        'A first date that turned into a cooking competition',
                    'body': 'We both said we could make the best pasta. Instead of picking a restaurant, we each made a dish and invited our friends to judge. I lost the competition, but the second date is already planned.',
                    'author': {
                      'id': 'demo-alex',
                      'username': 'alex_stories',
                      'display_name': 'Alex',
                    },
                    'is_anonymous': false,
                    'category': 'Dating',
                    'region': 'Philadelphia, PA',
                  },
                  {
                    'id': 'sample-2',
                    'title': 'My friend remembered the little things',
                    'body': 'I had mentioned once that I missed my old neighborhood bakery. My friend brought a box from there to our next game night. It was a small gesture that meant a lot after a long week.',
                    'author': null,
                    'is_anonymous': true,
                    'category': 'Friendship',
                  },
                ]
                .map(
                  (p) => {
                    ...p,
                    'is_mine': false,
                    'moderation_status': 'approved',
                    'created_at': now
                        .subtract(const Duration(hours: 2))
                        .toIso8601String(),
                    'expires_at': p['is_anonymous'] == true
                        ? now.add(const Duration(hours: 70)).toIso8601String()
                        : null,
                    'likes': p['id'] == 'sample-1' ? 12 : 8,
                    'dislikes': 1,
                    'comment_count': 0,
                    'responses': [],
                  },
                )
                .toList(),
        'comments': <dynamic>[],
        'groups': [
          {
            'id': 'group-1',
            'name': 'Philadelphia stories',
            'description': 'Firsthand experiences and local conversations.',
            'members': 24,
            'joined': true,
          },
          {
            'id': 'group-2',
            'name': 'Green flag moments',
            'description': 'Stories about thoughtful people.',
            'members': 36,
            'joined': false,
          },
        ],
        'activity': <dynamic>[],
        'reports': <dynamic>[],
        'media': <String, dynamic>{},
        'blocks': <dynamic>[],
        'settings': {
          'nearby_opt_in': false,
          'notifications': true,
          'region': 'Philadelphia, PA',
        },
      };
      await persist();
    }
    active.value = true;
  }

  static Future<void> persist() async => (await SharedPreferences.getInstance())
      .setString('defame_demo_v1', jsonEncode(state));
  static List<dynamic> get posts => state['posts'];
  static void event(String title, String body, [String? postId]) {
    (state['activity'] as List).insert(0, {
      'id': newId(),
      'title': title,
      'body': body,
      'post_id': postId,
      'is_read': false,
    });
  }

  static Map<String, dynamic> findPost(dynamic value) =>
      Map<String, dynamic>.from(
        posts.firstWhere(
          (p) => p['id'] == value,
          orElse: () => throw Exception('This post is unavailable.'),
        ),
      );
  static void updatePost(Map<String, dynamic> post) {
    final index = posts.indexWhere((p) => p['id'] == post['id']);
    posts[index] = post;
  }

  static Future<Map<String, dynamic>> call(
    String action,
    Map<String, dynamic> input,
  ) async {
    Map<String, dynamic> result = {};
    switch (action) {
      case 'capabilities':
        return {'ai_enabled': false};
      case 'feed':
        final q = '${input['query'] ?? ''}'.toLowerCase();
        final blocked = (state['blocks'] as List)
            .map((b) => b['post_id'])
            .toSet();
        var rows = posts
            .where(
              (p) =>
                  !blocked.contains(p['id']) &&
                  (input['mine'] == true
                      ? p['is_mine'] == true
                      : DraftRules.isVisible(
                          Map<String, dynamic>.from(p),
                          DateTime.now(),
                        )) &&
                  (input['author_id'] == null ||
                      p['author']?['id'] == input['author_id'] &&
                          p['is_anonymous'] != true) &&
                  (input['community_id'] == null ||
                      p['community_id'] == input['community_id']) &&
                  (q.isEmpty ||
                      '${p['title']} ${p['body']} ${p['category']}'
                          .toLowerCase()
                          .contains(q)),
            )
            .toList();
        if (input['filter'] == 'Popular') {
          rows.sort(
            (a, b) => DraftRules.score(
              b['likes'] ?? 0,
              b['dislikes'] ?? 0,
            ).compareTo(DraftRules.score(a['likes'] ?? 0, a['dislikes'] ?? 0)),
          );
        }
        if (input['filter'] == 'Nearby') {
          rows = rows
              .where((p) => p['region'] == state['settings']['region'])
              .toList();
        }
        result = {
          'posts': input['page'] == 0 ? rows : [],
          'people': [],
          'has_more': false,
        };
        break;
      case 'post':
        result = {'post': findPost(input['post_id'])};
        break;
      case 'publish':
        final issue = DraftRules.validate(
          input['title'],
          input['body'],
          input['subject_name'],
        );
        if (issue != null) throw Exception(issue);
        final prior = posts.where(
          (p) => p['request_id'] == input['request_id'],
        );
        if (prior.isNotEmpty) {
          return {
            'id': prior.first['id'],
            'status': prior.first['moderation_status'],
          };
        }
        final now = DateTime.now().toUtc();
        final post = <String, dynamic>{
          ...input,
          'id': newId(),
          'author': input['is_anonymous'] == true ? null : state['profile'],
          'is_mine': true,
          'moderation_status': 'approved',
          'created_at': now.toIso8601String(),
          'expires_at': input['is_anonymous'] == true
              ? now.add(const Duration(hours: 72)).toIso8601String()
              : null,
          'likes': 0,
          'dislikes': 0,
          'comment_count': 0,
          'responses': [],
          if (input['media_id'] != null)
            'media_url': state['media'][input['media_id']],
          'media_kind': 'image',
          if (input['poll'] != null)
            'poll': {
              ...input['poll'],
              'counts': List.filled(
                (input['poll']['options'] as List).length,
                0,
              ),
            },
        };
        posts.insert(0, post);
        event('Demo story published', 'Saved only on this device.', post['id']);
        result = {'id': post['id'], 'status': 'approved'};
        break;
      case 'upload':
        if (input['video'] == true) {
          throw Exception(
            'Video upload requires a connected account. The local demo supports photos.',
          );
        }
        final mediaId = newId();
        state['media'][mediaId] = 'data:image/jpeg;base64,${input['data']}';
        result = {'id': mediaId};
        break;
      case 'rewrite':
        throw Exception(
          'AI rewriting needs the server’s OpenAI API key. The local demo does not generate AI text.',
        );
      case 'react':
        final comment = input['comment_id'] != null;
        final row = comment
            ? (state['comments'] as List).firstWhere(
                (c) => c['id'] == input['comment_id'],
              )
            : findPost(input['post_id']);
        final old = row['my_reaction'];
        if (old != null) row['${old}s'] = (row['${old}s'] ?? 0) - 1;
        row['my_reaction'] = input['value'];
        if (input['value'] != null) {
          row['${input['value']}s'] = (row['${input['value']}s'] ?? 0) + 1;
        }
        if (!comment) updatePost(Map<String, dynamic>.from(row));
        result = {
          'likes': row['likes'] ?? 0,
          'dislikes': row['dislikes'] ?? 0,
          'my_reaction': row['my_reaction'],
        };
        break;
      case 'poll_vote':
        final p = findPost(input['post_id']);
        final spec = p['poll'];
        final old = spec['my_vote'];
        if (old != null) spec['counts'][old]--;
        spec['my_vote'] = input['option'];
        spec['counts'][input['option']]++;
        updatePost(p);
        result = {'poll': spec};
        break;
      case 'comments':
        result = {
          'comments': (state['comments'] as List)
              .where((c) => c['post_id'] == input['post_id'])
              .toList(),
          'has_more': false,
        };
        break;
      case 'comment':
        (state['comments'] as List).add({
          ...input,
          'id': newId(),
          'username': state['profile']['username'],
          'is_mine': true,
          'likes': 0,
          'dislikes': 0,
        });
        final p = findPost(input['post_id']);
        p['comment_count']++;
        updatePost(p);
        result = {'status': 'approved'};
        break;
      case 'delete_comment':
        final rows = state['comments'] as List;
        final row = rows.firstWhere((c) => c['id'] == input['comment_id']);
        final p = findPost(row['post_id']);
        p['comment_count']--;
        updatePost(p);
        rows.remove(row);
        break;
      case 'delete_post':
        posts.removeWhere((p) => p['id'] == input['post_id']);
        break;
      case 'block':
        (state['blocks'] as List).add({
          'id': newId(),
          'post_id': input['post_id'],
          'created_at': DateTime.now().toIso8601String(),
        });
        break;
      case 'unblock':
        (state['blocks'] as List).removeWhere(
          (b) => b['id'] == input['block_id'],
        );
        break;
      case 'profile':
        final own = input['user_id'] == null || input['user_id'] == userId;
        final profile = own
            ? Map<String, dynamic>.from(state['profile'])
            : <String, dynamic>{
                'id': input['user_id'],
                'username': 'alex_stories',
                'display_name': 'Alex',
                'bio': 'Sample profile',
              };
        result = {
          'profile': {
            ...profile,
            'posts': posts
                .where(
                  (p) =>
                      p['author']?['id'] == profile['id'] &&
                      p['is_anonymous'] != true &&
                      p['moderation_status'] == 'approved',
                )
                .toList(),
          },
        };
        break;
      case 'edit_profile':
        final name = '${input['username']}'.trim();
        if (!RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(name)) {
          throw Exception('Use 3–24 letters, numbers or underscores.');
        }
        if (['alex_stories', 'sample_member'].contains(name.toLowerCase())) {
          throw Exception('That username is already in use.');
        }
        (state['profile'] as Map).addAll(input);
        for (final p in posts) {
          if (p['is_mine'] == true && p['is_anonymous'] != true) {
            p['author'] = state['profile'];
          }
        }
        break;
      case 'settings':
        result = {'settings': state['settings'], 'blocks': state['blocks']};
        break;
      case 'preferences':
        (state['settings'] as Map).addAll(input);
        break;
      case 'communities':
        result = {
          'communities': (state['groups'] as List)
              .where(
                (g) =>
                    (input['joined_only'] != true || g['joined'] == true) &&
                    '${g['name']}'.toLowerCase().contains(
                      '${input['query'] ?? ''}'.toLowerCase(),
                    ),
              )
              .toList(),
        };
        break;
      case 'create_community':
        (state['groups'] as List).add({
          ...input,
          'id': newId(),
          'members': 1,
          'joined': true,
        });
        break;
      case 'join':
        final g = (state['groups'] as List).firstWhere(
          (g) => g['id'] == input['community_id'],
        );
        if (g['joined'] != input['join']) {
          g['members'] += input['join'] == true ? 1 : -1;
        }
        g['joined'] = input['join'];
        break;
      case 'activity':
        result = {'activity': state['activity']};
        break;
      case 'read_activity':
        for (final row in state['activity']) {
          if (input['id'] == null || row['id'] == input['id']) {
            row['is_read'] = true;
          }
        }
        break;
      case 'report':
      case 'response':
        (state['reports'] as List).add({
          ...input,
          'id': newId(),
          'type': action,
          'status': 'pending',
        });
        event(
          'Demo request submitted',
          'Saved locally for your walkthrough.',
          input['post_id'],
        );
        break;
      case 'moderation_queue':
        result = {
          'items': (state['reports'] as List)
              .where((r) => r['status'] == 'pending')
              .toList(),
        };
        break;
      case 'moderate':
        final r = (state['reports'] as List).firstWhere(
          (r) => r['id'] == input['id'],
        );
        r['status'] = 'resolved';
        event('Demo request reviewed', '${input['note']}', r['post_id']);
        break;
      case 'export':
        result = state;
        break;
      case 'delete_account':
        await (await SharedPreferences.getInstance()).remove('defame_demo_v1');
        state = {};
        active.value = false;
        return {'ok': true};
      default:
        throw Exception('This action requires a connected account.');
    }
    await persist();
    return result;
  }
}
