import 'package:cse1_univents/src/models/attendee_model.dart';
import 'package:cse1_univents/src/models/event_model.dart';
import 'package:cse1_univents/src/models/organization_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataProvider extends ChangeNotifier {
  List<Organization>? orgs;
  List<Event>? events;
  List<Attendee>? attendees;

  Future<void> fetchOrgs() async {
    final res = await Supabase.instance.client.from('organizations').select();
    orgs = (res as List).map((m) => Organization.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> fetchEvents() async {
    final res = await Supabase.instance.client.from('events').select();
    events = (res as List).map((m) => Event.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> fetchAttendees() async {
    final res = await Supabase.instance.client.from('attendees').select();
    attendees = (res as List).map((m) => Attendee.fromMap(m)).toList();
    notifyListeners();
  }
}