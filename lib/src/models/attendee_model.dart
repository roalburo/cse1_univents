// models/attendee.dart
class Attendee {
  final String uid;
  final String accountid;
  final DateTime datetimestamp;
  final bool status;
  final String eventid;

  Attendee({
    required this.uid,
    required this.accountid,
    required this.datetimestamp,
    required this.status,
    required this.eventid,
  });

  factory Attendee.fromMap(Map<String, dynamic> m) => Attendee(
        uid: m['uid'] as String,
        accountid: m['accountid'] as String,
        datetimestamp: DateTime.parse(m['datetimestamp'] as String),
        status: m['status'] as bool,
        eventid: m['eventid'] as String,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'accountid': accountid,
        'datetimestamp': datetimestamp.toIso8601String(),
        'status': status,
        'eventid': eventid,
      };
}