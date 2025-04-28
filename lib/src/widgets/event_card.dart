import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _showDetails = false;
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
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Full background event image
          Positioned.fill(
            child: Image.network(
              widget.event.banner,
              fit: BoxFit.cover,
            ),
          ),

          // Optional dark gradient for better text contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // Expandable content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Center(
                    child: Text(
                      widget.event.title,
                      style: GoogleFonts.poppins(
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Toggle button positioned separately from the content
                IconButton(
                  icon: Icon(
                    _showDetails
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                ),

                AnimatedCrossFade(
                  firstChild: SizedBox.shrink(),
                  secondChild: Container(
                    height: 280, // Set a fixed height
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.black.withOpacity(0.7),
                    child: SingleChildScrollView( // Wrap the details in SingleChildScrollView
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoading
                                ? "Loading organization..."
                                : "Organization: $orgName",
                            style: GoogleFonts.poppins(
                              color: Colors.blue[300],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.event.title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${DateFormat('MMM dd, yyyy hh:mm a').format(widget.event.datetimestart)} - '
                                  '${DateFormat('MMM dd, yyyy hh:mm a').format(widget.event.datetimeend)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.event.description,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Location: ${widget.event.location}',
                                  style: GoogleFonts.poppins(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.local_offer, color: Colors.green[400], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                widget.event.type.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.green[400],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Tags: ${widget.event.tags.join(', ')}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showDetails = false; // Minimize the details when back is pressed
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  crossFadeState: _showDetails ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
