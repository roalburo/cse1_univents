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
    Size screenSize = MediaQuery.of(context).size;
    final events = context.watch<DataProvider>().events ?? [];
    final orgs = context.watch<DataProvider>().orgs ?? [];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Events',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 35,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.black, Colors.blue[900]!],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 3,
              width: 500,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'ADD/EDIT'), Tab(text: 'MANAGE')],
          labelColor: Colors.blue[900],
          unselectedLabelColor: Colors.black,
          labelStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
          indicator: const BoxDecoration(),
        ),
      ),
      body: Container(
          decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/ccfc.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken,
            ),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: screenSize.width * 0.3,
                  height: screenSize.height * 0.7,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.lightBlueAccent,
                        Colors.blue[900]!,
                      ],
                      ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_bannerBytes != null)
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Image.memory(_bannerBytes!, height: 150),
                                        ),
                                        ElevatedButton(
                                          onPressed: _pickImage,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            elevation: 4,
                                            shadowColor: Colors.black45,
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.black, Colors.blue[900]!],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.image, color: Colors.white),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    _bannerBytes == null ? 'Pick Banner' : 'Banner Picked',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                      SizedBox(height: 20),
                                      DropdownButtonFormField<String>(
                                        value: _selectedOrgUid,
                                        dropdownColor: Colors.black, // Dropdown menu background
                                        decoration: InputDecoration(
                                          labelText: 'Organization',
                                          labelStyle: GoogleFonts.poppins(color: Colors.white),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white, width: 2.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white, width: 3.0),
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white),
                                          ),
                                        ),
                                        iconEnabledColor: Colors.white,
                                        style: GoogleFonts.poppins(color: Colors.white), // Text style of selected item
                                        items: orgs.map((org) {
                                          return DropdownMenuItem(
                                            value: org.uid,
                                            child: Text(
                                              org.name,
                                              style: GoogleFonts.poppins(color: Colors.white), // Text style in dropdown list
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) => setState(() => _selectedOrgUid = value),
                                        validator: (value) => value == null ? 'Required' : null,
                                      ),

                                      SizedBox(height: 20),
                                      ..._controllers.entries.map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: TextFormField(
                                          controller: e.value,
                                          style: GoogleFonts.poppins(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: e.key.capitalize(),
                                            labelStyle: GoogleFonts.poppins(color: Colors.white),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white, width: 3.0),
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.white),
                                            ),
                                            hintStyle: TextStyle(color: Colors.white70),
                                          ),
                                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                        ),                                    
                                      )),
                                      SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ListTile(
                                              title: Text(
                                                _datetimeStart == null ? 'Select Start' : _datetimeStart.toString(),
                                                style: GoogleFonts.poppins(color: Colors.white),
                                              ),
                                              trailing: Icon(Icons.calendar_today, color: Colors.white),
                                              onTap: () => _selectDateTime(true),
                                            ),
                                          ),
                                          Expanded(
                                            child: ListTile(
                                              title: Text(
                                                _datetimeEnd == null ? 'Select End' : _datetimeEnd.toString(),
                                                style: GoogleFonts.poppins(color: Colors.white),
                                              ),
                                              trailing: Icon(Icons.calendar_today, color: Colors.white),
                                              onTap: () => _selectDateTime(false),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                      DropdownButtonFormField<String>(
                                        value: _status,
                                        dropdownColor: Colors.black, // Optional: background of dropdown menu
                                        decoration: InputDecoration(
                                          labelText: 'Status',
                                          labelStyle: GoogleFonts.poppins(color: Colors.white),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white, width: 2.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white, width: 3.0),
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white),
                                          ),
                                        ),
                                        iconEnabledColor: Colors.white,
                                        style: GoogleFonts.poppins(color: Colors.white),
                                        items: ['active', 'pending', 'done'].map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              s,
                                              style: GoogleFonts.poppins(color: Colors.white),
                                            ),
                                          ),
                                        ).toList(),
                                        onChanged: (value) => setState(() => _status = value),
                                        validator: (value) => value == null ? 'Required' : null,
                                      ),

                                      SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: _submitEvent,
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          backgroundColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          elevation: 4,
                                          shadowColor: Colors.black45,
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.black, Colors.blue[900]!],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Container(
                                            width: screenSize.width * 0.5,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.event, color: Colors.white),
                                                SizedBox(width: 8),
                                                Text(
                                                  _editingUid == null ? 'Add Event' : 'Update Event',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
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
                  ),
                ),
              ),
            ),
            ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(204, 0, 0, 0),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      image: event.banner != null && event.banner!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(event.banner!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: event.banner == null || event.banner!.isEmpty
                        ? Icon(Icons.image_not_supported, color: Colors.white)
                        : null,
                  ),
                  title: Text(event.title ?? '', style: GoogleFonts.poppins(color: Colors.white)),
                  subtitle: Text(event.location ?? '', style: GoogleFonts.poppins(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.lightGreenAccent),
                        onPressed: () => _loadEventForEditing(event),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEvent(event.uid),
                      ),
                    ],
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}