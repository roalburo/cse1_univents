import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendee_model.dart';

class AttendeeCard extends StatefulWidget {
  final Attendee attendee;

  const AttendeeCard({super.key, required this.attendee});

  @override
  State<AttendeeCard> createState() => _AttendeeCardState();
}

class _AttendeeCardState extends State<AttendeeCard> {
  String? fullName;
  String? eventName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendeeName();
    fetchEventName();
  }

  Future<void> fetchAttendeeName() async {
    try {
      final response = await Supabase.instance.client
        .from('accounts')
        .select('firstname, lastname, email')
        .eq('uid', widget.attendee.accountid)
        .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          fullName = '${response['firstname']} ${response['lastname']}';
          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          fullName = "Unknown Attendee";
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchEventName() async {
    try {
      final response = await Supabase.instance.client
        .from('events')
        .select('title')
        .eq('uid', widget.attendee.eventid)
        .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          eventName = '${response['title']}';
          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          eventName = "Unknown Event";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.badge, color: Colors.blueAccent, size: 28),
            const SizedBox(height: 8),
            Text(
              isLoading
                ? "Loading name..."
                : "Attendee: $fullName",
            ),
            const SizedBox(height: 6),
            Text(
              isLoading
                ? "Loading event..."
                : "Event Joined: $eventName",
            ),
            Text(
              'Date joined: ${DateFormat('MMM dd, yyyy  hh:mm a').format(widget.attendee.datetimestamp)}'
            ),
          ],
        ),
      ),
    );
  }
}
