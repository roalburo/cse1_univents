// models/event.dart
class Event {
  final String uid;
  final String banner;
  final String orguid;
  final String title;
  final String description;
  final String location;
  final String type;
  final DateTime datetimestart;
  final DateTime datetimeend;
  final String status;
  final List<String> tags;

  Event({
    required this.uid,
    required this.banner,
    required this.orguid,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.datetimestart,
    required this.datetimeend,
    required this.status,
    required this.tags,
  });

  factory Event.fromMap(Map<String, dynamic> m) => Event(
        uid: m['uid'] as String,
        banner: m['banner'] as String,
        orguid: m['orguid'] as String,
        title: m['title'] as String,
        description: m['description'] as String,
        location: m['location'] as String,
        type: m['type'] as String,
        datetimestart: DateTime.parse(m['datetimestart'] as String),
        datetimeend: DateTime.parse(m['datetimeend'] as String),
        status: m['status'] as String,
        tags: List<String>.from(m['tags'] as List<dynamic>),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'banner': banner,
        'orguid': orguid,
        'title': title,
        'description': description,
        'location': location,
        'type': type,
        'datetimestart': datetimestart.toIso8601String(),
        'datetimeend': datetimeend.toIso8601String(),
        'status': status,
        'tags': tags,
      };
}
