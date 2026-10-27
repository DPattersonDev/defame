/// Fast feedback only. The server always performs authoritative checks.
class DraftRules {
  static const categories = [
    'Dating',
    'Relationship',
    'Friendship',
    'Family',
    'Work',
    'School',
    'Social',
    'Other',
  ];

  static String? validate(String title, String body, String subject) {
    if (title.trim().length < 3 || title.trim().length > 120) {
      return 'Use a title between 3 and 120 characters.';
    }
    if (body.trim().length < 10 || body.trim().length > 10000) {
      return 'Write between 10 and 10,000 characters about your experience.';
    }
    if (subject.trim().length > 40 ||
        (subject.trim().isNotEmpty &&
            !RegExp(r'^[A-Za-z][A-Za-z-]{0,28}( [A-Za-z]\.)?$')
                .hasMatch(subject.trim()))) {
      return 'Use only a first name or first name and last initial for the subject.';
    }
    final text = '$title $body $subject';
    if (RegExp(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b').hasMatch(text) ||
        RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}').hasMatch(text)) {
      return 'Remove private phone numbers and email addresses before sharing.';
    }
    return null;
  }

  static int score(int likes, int dislikes) => likes - dislikes;

  static bool isVisible(Map<String, dynamic> post, DateTime now) {
    final expiration = DateTime.tryParse('${post['expires_at']}');
    return post['moderation_status'] == 'approved' &&
        (expiration == null || expiration.isAfter(now));
  }
}
