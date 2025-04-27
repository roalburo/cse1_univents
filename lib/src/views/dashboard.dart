import 'package:cse1_univents/src/models/attendee_model.dart';
import 'package:cse1_univents/src/models/event_model.dart';
import 'package:cse1_univents/src/models/organization_model.dart';
import 'package:cse1_univents/src/views/login.dart';
import 'package:cse1_univents/src/widgets/attendee_card.dart';
import 'package:cse1_univents/src/widgets/event_card.dart';
import 'package:cse1_univents/src/widgets/organization_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3 / 4,
          ),
          itemCount: organizations.length,
          itemBuilder: (context, index) {
            final org = organizations[index];
            return OrganizationCard(org: org);
          },
        ),
      );
    } else if (selectedIndex == 1) {
      return Expanded(
        child: GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3 / 4,
          ),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(event: event);
          },
        ),
      );
    } else {
      return Expanded(
        child: GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3 / 4,
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
    final toggleTitles = ['Organizations', 'Events', 'Attendees'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('Organizations'),
              onTap: () {
                Navigator.pushNamed(context, '/orgs');
              },
            ),
            ListTile(
              title: Text('Events'),
              onTap: () {
                Navigator.pushNamed(context, '/events');
              },
            ),
            ListTile(
              title: Text('Attendees'),
              onTap: () {
                Navigator.pushNamed(context, '/attendees');
              },
            ),
          ],
        )
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              borderRadius: BorderRadius.circular(8),
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
              children: toggleTitles.map((title) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(title),
              )).toList(),
            ),
            SizedBox(height: 20,),
            getDataWidget(),
            SizedBox(height: 20,),
            ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Logout'),
            )
          ],
        ),
      ),
    );
  }
}