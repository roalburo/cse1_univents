import 'package:flutter/material.dart';
import '../models/attendee_model.dart';

class AttendeeCard extends StatelessWidget {
  final Attendee attendee;

  const AttendeeCard({super.key, required this.attendee});

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
              "Attendee ID: ${attendee.accountid}",
            ),
            const SizedBox(height: 6),
            Text(
              "Event ID: ${attendee.eventid}",
            ),
          ],
        ),
      ),
    );
  }
}
