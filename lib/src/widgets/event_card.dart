import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart';

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  String? orgName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrgName();
  }

  Future<void> fetchOrgName() async {
    try {
      final res = await Supabase.instance.client
        .from('organizations')
        .select('acronym')
        .eq('uid', widget.event.orguid)
        .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          orgName = '${res['acronym']}';
          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          orgName = "Unknown Organization";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            widget.event.banner,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                    ? "Loading organization..."
                    : "Organization: $orgName",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  widget.event.title,
                ),
                const SizedBox(height: 5),
                Text(
                  '${DateFormat('MMM dd, yyyy  hh:mm a').format(widget.event.datetimestart)}'
                  ' – ${DateFormat('MMM dd, yyyy hh:mm a').format(widget.event.datetimeend)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  child: Text(
                    widget.event.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Location: ${widget.event.location}',
                ),
                Text(
                  widget.event.type
                ),
                Text(
                  widget.event.tags.join(', '),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}