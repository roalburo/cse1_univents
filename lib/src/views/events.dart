import 'package:cse1_univents/src/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:cse1_univents/src/services/data_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

extension StringCapitalization on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'title': TextEditingController(),
    'description': TextEditingController(),
    'location': TextEditingController(),
    'type': TextEditingController(),
    'tags': TextEditingController(),
  };
  String? _selectedOrgUid;
  Uint8List? _bannerBytes;
  String? _bannerFileName;
  String? _status = 'active';
  String? _editingUid;
  DateTime? _datetimeStart;
  DateTime? _datetimeEnd;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final provider = context.read<DataProvider>();
      provider.fetchEvents();
      provider.fetchOrgs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String fileName) async {
    final storage = Supabase.instance.client.storage.from('assets');
    final filePath = 'event_banners/$fileName';

    try {
      final response = await storage.uploadBinary(
        filePath,
        imageBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      if (response.isEmpty) return null;
      return storage.getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bannerBytes == null && _editingUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a banner image.')),
      );
      return;
    }
    if (_selectedOrgUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an organization.')),
      );
      return;
    }
    String? bannerUrl;
    if (_bannerBytes != null && _bannerFileName != null) {
      bannerUrl = await _uploadImage(_bannerBytes!, _bannerFileName!);
    }
    final tagsList = _controllers['tags']!.text.split(', ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final map = {
      'orguid': _selectedOrgUid,
      'title': _controllers['title']!.text,
      'description': _controllers['description']!.text,
      'location': _controllers['location']!.text,
      'type': _controllers['type']!.text,
      'status': _status,
      'tags': tagsList,
      'datetimestart': _datetimeStart?.toIso8601String(),
      'datetimeend': _datetimeEnd?.toIso8601String(),
    };
    if (bannerUrl != null) map['banner'] = bannerUrl;

    try {
      if (_editingUid == null) {
        final response = await Supabase.instance.client.from('events').insert(map).select();
        if (response == null || response is! List || response.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to insert event.')));
          return;
        }
      } else {
        final response = await Supabase.instance.client.from('events').update(map).eq('uid', _editingUid!).select();
        if (response == null || response is! List || response.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update event.')));
          return;
        }
      }
      _clearForm();
      await context.read<DataProvider>().fetchEvents();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event saved.')));
    } catch (e) {
      print("Databse error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save event.')));
    }
  }

  void _clearForm() {
    _controllers.forEach((_, c) => c.clear());
    _bannerBytes = null;
    _bannerFileName = null;
    _selectedOrgUid = null;
    _editingUid = null;
    _status = 'active';
    _datetimeStart = null;
    _datetimeEnd = null;
  }

  void _loadEventForEditing(Event event) async {
      _editingUid = event.uid;
      _selectedOrgUid = event.orguid;
      _controllers['title']!.text = event.title;
      _controllers['description']!.text = event.description;
      _controllers['location']!.text = event.location;
      _controllers['type']!.text = event.type;
      _controllers['tags']!.text = (event.tags as List<dynamic>).join(', ') ?? '';
      _status = event.status;
      _datetimeStart = event.datetimestart;
      _datetimeEnd = event.datetimeend;
      // _bannerBytes = null;
      // _bannerFileName = null;

      if (event.banner.isNotEmpty) {
        final response = await http.get(Uri.parse(event.banner));
        if (response.statusCode == 200) {
          _bannerBytes = response.bodyBytes;
          _bannerFileName = event.banner.split('/').last;
        }
      }
      setState(() {});
      _tabController.animateTo(0); // Switch to Add/Edit tab
  }

  Future<void> _deleteEvent(String uid) async {
    try {
      await Supabase.instance.client.from('events').delete().eq('uid', uid);
      await context.read<DataProvider>().fetchEvents();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event deleted.')));
    } catch (e) {
      print("Error deleting event: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete event.')));
    }
  }

  Future<void> _pickImage() async {
    final mediaData = await ImagePickerWeb.getImageAsBytes();
    final info = await ImagePickerWeb.getImageInfo();
    if (mediaData != null && info != null) {
      setState(() {
        _bannerBytes = mediaData;
        _bannerFileName = info.fileName!;
      });
    }
  }

  Future<void> _selectDateTime(bool isStart) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(Duration(days: 365)),
      lastDate: now.add(Duration(days: 365)),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isStart) {
            _datetimeStart = selectedDateTime;
          } else {
            _datetimeEnd = selectedDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<DataProvider>().events ?? [];
    final orgs = context.watch<DataProvider>().orgs ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Events', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Add/Edit'), Tab(text: 'Manage')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  if (_bannerBytes != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Image.memory(_bannerBytes!, height: 150),
                    ),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.image),
                    label: Text(_bannerBytes == null ? 'Pick Banner' : 'Banner Picked'),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedOrgUid,
                    items: orgs.map((org) {
                      return DropdownMenuItem(value: org.uid, child: Text(org.name));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedOrgUid = value),
                    decoration: InputDecoration(
                      labelText: 'Organization',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  ..._controllers.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: e.value,
                      decoration: InputDecoration(labelText: e.key.capitalize(), border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  )),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(_datetimeStart == null ? 'Select Start' : _datetimeStart.toString()),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () => _selectDateTime(true),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text(_datetimeEnd == null ? 'Select End' : _datetimeEnd.toString()),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () => _selectDateTime(false),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: ['active', 'pending', 'done']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  ElevatedButton(
                    onPressed: _submitEvent,
                    child: Text(_editingUid == null ? 'Add Event' : 'Update Event'),
                  ),
                ],
              ),
            ),
          ),
          ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: event.banner != null && event.banner!.isNotEmpty
                  ? NetworkImage(event.banner)
                  : null,
                  child: event.banner == null || event.banner!.isEmpty
                  ? Icon(Icons.image_not_supported)
                  : null,
                  ),
                title: Text(event.title ?? ''),
                subtitle: Text(event.location ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit), onPressed: () => _loadEventForEditing(event)),
                    IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEvent(event.uid)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}