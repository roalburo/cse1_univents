import 'package:cse1_univents/src/models/attendee_model.dart';
import 'package:cse1_univents/src/models/event_model.dart';
import 'package:cse1_univents/src/models/organization_model.dart';
import 'package:cse1_univents/src/views/login.dart';
import 'package:cse1_univents/src/widgets/attendee_card.dart';
import 'package:cse1_univents/src/widgets/event_card.dart';
import 'package:cse1_univents/src/widgets/organization_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  bool isExpanded = false;
  List<Organization> organizations = [];
  List<Event> events = [];
  List<Attendee> attendees = [];

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    await fetchOrganizations();
    await fetchEvents();
    await fetchAttendees();
  }

  Future<void> fetchOrganizations() async {
    final res = await Supabase.instance.client.from('organizations').select();
    if (mounted) {
      setState(() {
        organizations = (res as List).map((m) => Organization.fromMap(m)).toList();
      });
    }
  }

  Future<void> fetchEvents() async {
    final res = await Supabase.instance.client.from('events').select();
    if (mounted) {
      setState(() {
        events = (res as List).map((m) => Event.fromMap(m)).toList();
      });
    }
  }

  Future<void> fetchAttendees() async {
    final res = await Supabase.instance.client.from('attendees').select();
    if (mounted) {
      setState(() {
        attendees = (res as List).map((m) => Attendee.fromMap(m)).toList();
      });
    }
  }

  Widget getDataWidget() {
    if (selectedIndex == 0) {
      return Expanded(
        child: GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 700,
            mainAxisExtent: 300,
            crossAxisSpacing: 12,
            mainAxisSpacing: 24,
            childAspectRatio: 1,
          ),
          itemCount: organizations.length,
          itemBuilder: (context, index) {
            final org = organizations[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: OrganizationCard(org: org),
            );
          },
        ),
      );
    } else if (selectedIndex == 1) {
      return Expanded(
        child: GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500,
            mainAxisExtent: 300,
            crossAxisSpacing: 12,
            mainAxisSpacing: 24,
            childAspectRatio: 1,
          ),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: EventCard(event: event),
            );
          },
        ),
      );
    } else {
      return Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400, // maximum width for a card
            mainAxisExtent: 200,
            mainAxisSpacing: 24,
            crossAxisSpacing: 12,
            childAspectRatio: 1, // optional fine-tuning (but less important here)
          ),
          itemCount: attendees.length,
          itemBuilder: (context, index) {
            final att = attendees[index];
            return AttendeeCard(attendee: att);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggleTitles = ['ORGANIZATIONS', 'EVENTS', 'ATTENDEES'];

    return Scaffold(
    appBar: AppBar(
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Image.asset('assets/logo.png', width: 50, height: 50),
          ),
          Text(
            'Ateneo Events',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: isExpanded ? 200 : 40,
          height: 30,
          child: Row(
            children: [
              Expanded(
                child: isExpanded
                    ? TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: GoogleFonts.poppins(fontSize: 14),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      )
                    : SizedBox.shrink(),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Icon(Icons.search),
              ),
            ],
          ),
        ),
        SizedBox(width: 16), // spacing between search and toggle buttons
        ToggleButtons(
          borderWidth: 0,
          borderColor: Colors.transparent,
          selectedBorderColor: Colors.transparent,
          fillColor: Colors.transparent,
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          isSelected: [
            selectedIndex == 0,
            selectedIndex == 1,
            selectedIndex == 2,
          ],
          onPressed: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          children: List.generate(toggleTitles.length, (index) {
            final isSelectedNow = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
          toggleTitles[index],
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isSelectedNow ? Colors.blue[900] : Colors.black,
            letterSpacing: isSelectedNow ? 1.5 : 1.0,
          ),
              ),
            );
          }),
        ),
        SizedBox(width: 16), // spacing before hamburger
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ),
      ],
    ),


    endDrawer: Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue[900],
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Hello, User!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(thickness: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.business, color: Colors.blueGrey),
                    title: Text(
                      'Organizations',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/orgs');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.event, color: Colors.blueGrey),
                    title: Text(
                      'Events',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/events');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.people, color: Colors.blueGrey),
                    title: Text(
                      'Attendees',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),   
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/attendees');
                    },
                  ),
                ],
              ),
            ),
            Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50),
                  backgroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.logout, size: 20, color: Colors.white,),
                label: Text(
                  'Logout',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                ),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),


      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
              padding: const EdgeInsets.only(left: 9.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  toggleTitles[selectedIndex],
                  style: GoogleFonts.poppins(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  foreground: Paint()
                    ..shader = LinearGradient(
                    colors: [Colors.black, Colors.blue[900]!],
                    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                  ),
                ),
                SizedBox(height: 4), // Add a small gap between text and underline
                Container(
                  height: 3,
                    width: 350, // Adjust the width of the underline as needed
                    decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Colors.blue[900]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    ),
                ),
                ],
              ),
              ),
            ),
            SizedBox(height: 20),
            getDataWidget(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
