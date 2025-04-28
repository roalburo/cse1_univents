import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendee_model.dart';
import 'package:google_fonts/google_fonts.dart';


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
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
      decoration: BoxDecoration(
      gradient: LinearGradient(
      colors: [Colors.white, Colors.blueGrey[50]!],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
      children: [
        Container(
        width: 8,
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          ),
        ),
        ),
        SizedBox(width: 8),
        Expanded(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.blue[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            ),
            child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
          ),
          ),
          const SizedBox(height: 14),
          Row(
          children: [
            Icon(Icons.person, color: Colors.blueGrey, size: 24),
            const SizedBox(width: 8),
            RichText(
            text: TextSpan(
            text: 'Attendee: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.black),
            children: [
            TextSpan(
              text: isLoading ? "Loading name..." : fullName,
              style: GoogleFonts.poppins(
              fontWeight: FontWeight.normal,
              color: Colors.black),
            ),
            ],
            ),
            ),
          ],
          ),
          const SizedBox(height: 6),
          Row(
          children: [
            Icon(Icons.event, color: Colors.blueGrey, size: 24),
            const SizedBox(width: 8),
            RichText(
            text: TextSpan(
            text: 'Event Joined: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.black),
            children: [
            TextSpan(
              text: isLoading ? "Loading event..." : eventName,
              style: GoogleFonts.poppins(
              fontWeight: FontWeight.normal,
              color: Colors.black),
            ),
            ],
            ),
            ),
          ],
          ),
          const SizedBox(height: 6),
          Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blueGrey, size: 24),
            const SizedBox(width: 8),
            RichText(
            text: TextSpan(
            text: 'Date Joined: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.black),
            children: [
            TextSpan(
              text: DateFormat('MMM dd, yyyy  hh:mm a')
              .format(widget.attendee.datetimestamp),
              style: GoogleFonts.poppins(
              fontWeight: FontWeight.normal,
              color: Colors.black),
            ),
            ],
            ),
            ),
          ],
          ),
          ],
          ),
        ),
        ),
      ],
      ),
      ),
    );
  }
}
