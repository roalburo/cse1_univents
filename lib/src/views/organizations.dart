import 'package:cse1_univents/main.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:cse1_univents/src/models/organization_model.dart';
import 'package:cse1_univents/src/services/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}
extension StringCapitalization on String {
  String capitalize() {
    if (this.isEmpty) {
      return this;
    }
    return this[0].toUpperCase() + this.substring(1);
  }
}
class _OrganizationsScreenState extends State<OrganizationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'acronym': TextEditingController(),
    'name': TextEditingController(),
    'category': TextEditingController(),
    'email': TextEditingController(),
    'mobile': TextEditingController(),
    'facebook': TextEditingController(),
  };
  Uint8List? _logoBytes, _bannerBytes;
  String? _logoFileName, _bannerFileName;
  bool _status = true;
  String? _editingUid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => context.read<DataProvider>().fetchOrgs()); // Fetch organizations when the screen is initialized
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String fileName, String folder) async {
    final storage = Supabase.instance.client.storage.from('assets');
    final filePath = '$folder/$fileName';

    try {
      // Upload the image
      final response = await storage.uploadBinary(
        filePath,
        imageBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      // Log the result
      print('📦 Upload response: $response');
      if (response.isEmpty) {
        print("⚠️ Upload failed — empty response");
        return null;
      }
      // Get the public URL
      final publicUrl = storage.getPublicUrl(filePath);
      print('Public image URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitOrg() async {
    if (!_formKey.currentState!.validate()) return;
    // Require both logo and banner before proceeding for new orgs
    if ((_logoBytes == null || _bannerBytes == null) && _editingUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both logo and banner images.')),
      );
      return;
    }

    // Upload images to correct folders and get public URLs
    String? logoUrl, bannerUrl;
    if (_logoBytes != null && _logoFileName != null) {
      logoUrl = await _uploadImage(_logoBytes!, _logoFileName!, 'org_logos');
    }
    if (_bannerBytes != null && _bannerFileName != null) {
      bannerUrl = await _uploadImage(_bannerBytes!, _bannerFileName!, 'org_banners');
    }
    final map = {
      'acronym': _controllers['acronym']!.text,
      'name': _controllers['name']!.text,
      'category': _controllers['category']!.text,
      'email': _controllers['email']!.text,
      'mobile': _controllers['mobile']!.text,
      'facebook': _controllers['facebook']!.text,
      'status': _status,
    };
    if (logoUrl != null) map['logo'] = logoUrl;
    if (bannerUrl != null) map['banner'] = bannerUrl;
    try {
      if (_editingUid == null) {
        final response = await supabase.from('organizations').insert(map).select();

        if (response == null || response is! List || response.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to insert organization.')),
          );
          return;
        }
        print("Insert successful: $response");
      } else {
        final response = await supabase.from('organizations').update(map).eq('uid', _editingUid!).select();

        if (response == null || response is! List || response.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update organization.')),
          );
          return;
        }
        print("Update successful: $response");
      }
      _clearForm();
      await context.read<DataProvider>().fetchOrgs();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Organization saved.')));
    } catch (e) {
      print("Error during database operation: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save organization.')));
    }
  }

  void _clearForm() {
    _controllers.forEach((_, c) => c.clear());
    _logoBytes = null;
    _bannerBytes = null;
    _logoFileName = null;
    _bannerFileName = null;
    _editingUid = null;
    _status = true;
  }

  Future<void> _deleteOrg(String uid) async {
    try {
      // Check if the organization has linked events
      final linkedEvents = await Supabase.instance.client
          .from('events')
          .select()
          .eq('organization_uid', uid);

      if (linkedEvents != null && linkedEvents.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This organization has events and cannot be deleted.')),
        );
        return;
      }
      // Proceed with deletion if no linked events
      await Supabase.instance.client.from('organizations').delete().eq('uid', uid);
      if (mounted) {
        await context.read<DataProvider>().fetchOrgs();
      }
    } catch (e) {
      print('Error deleting organization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete organization.')),
        );
      }
    }
  }

  void _loadOrgForEditing(Organization org) async {
    _controllers['acronym']!.text = org.acronym;
    _controllers['name']!.text = org.name;
    _controllers['category']!.text = org.category;
    _controllers['email']!.text = org.email;
    _controllers['mobile']!.text = org.mobile;
    _controllers['facebook']!.text = org.facebook;
    _status = org.status;
    _editingUid = org.uid;

    if (org.logo.isNotEmpty) { // Load logo
      final response = await http.get(Uri.parse(org.logo));
      if (response.statusCode == 200) {
        _logoBytes = response.bodyBytes;
        _logoFileName = org.logo.split('/').last;
      }
    }
    
    if (org.banner.isNotEmpty) { // Load banner
      final response = await http.get(Uri.parse(org.banner));
      if (response.statusCode == 200) {
        _bannerBytes = response.bodyBytes;
        _bannerFileName = org.banner.split('/').last;
      }
    }

    setState(() {});
    _tabController.animateTo(0);
  }

  Future<void> _pickImage(bool isLogo) async {
    final mediaData = await ImagePickerWeb.getImageAsBytes();
    final info = await ImagePickerWeb.getImageInfo();

    if (mediaData != null && info != null) {
      setState(() {
        if (isLogo) {
          _logoBytes = mediaData;
          _logoFileName = info.fileName!;
        } else {
          _bannerBytes = mediaData;
          _bannerFileName = info.fileName!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
  Size screenSize = MediaQuery.of(context).size;

    final orgs = context.watch<DataProvider>().orgs ?? [];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Organizations',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, 
                  fontSize: 35,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [Colors.black, Colors.blue[900]!],
                    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),)),
            SizedBox(height: 5),
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
          labelColor: Colors.blue[900], // Optional: overrides default color
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
          indicator: BoxDecoration(),         
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
                  height: screenSize.height * 0.65,
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
                      padding: const EdgeInsets.all(10.0),
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
                                      if (_logoBytes != null)
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Image.memory(_logoBytes!, height: 150,),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _pickImage(true),
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
                                                    _logoBytes == null ? 'Pick Logo' : 'Logo Picked',
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
        
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (_bannerBytes != null)
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Image.memory(_bannerBytes!, height: 150,),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _pickImage(false),
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
        
                                    ],
                                  ),
                                ),
                              ],
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
                                  hintStyle: TextStyle(color: Colors.white70), // in case you use hintText
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            )),
                            SizedBox(height: 20),
                            SwitchListTile(
                              title: Text('Active Status', style: GoogleFonts.poppins(color: Colors.white),),
                              value: _status,
                              activeColor: Colors.lightGreenAccent,
                              inactiveThumbColor: Colors.white, 
                              inactiveTrackColor: Colors.grey[600], 
                              onChanged: (v) => setState(() => _status = v),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _submitOrg,
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
                                      Icon(Icons.business, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        _editingUid == null ? 'Add Organization' : 'Update Organization',
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
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ListView.builder(
              itemCount: orgs.length,
              itemBuilder: (context, index) {
                final org = orgs[index];
                return ListTile(
                leading: Container(
                  width: 50, // or your preferred size
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
                    image: DecorationImage(
                      image: NetworkImage(org.logo ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                  title: Text(org.name, style: GoogleFonts.poppins(color:Colors.white),),
                  subtitle: Text(org.acronym, style: GoogleFonts.poppins(color:Colors.white),),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit, color: Colors.lightGreenAccent), onPressed: () => _loadOrgForEditing(org)),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteOrg(org.uid!)),
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