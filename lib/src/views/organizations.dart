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
    // Fetch organizations when the screen is initialized
    Future.microtask(() => context.read<DataProvider>().fetchOrgs());
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
      print('✅ Public image URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitOrg() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Require both logo and banner before proceeding
    if (_logoBytes == null || _bannerBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload both logo and banner images.')),
      );
      return;
    }

    final supabase = Supabase.instance.client;

    // ✅ Upload images to correct folders and get public URLs
    String? logoUrl, bannerUrl;
    if (_logoBytes != null && _logoFileName != null) {
      print("Uploading logo...");
      logoUrl = await _uploadImage(_logoBytes!, _logoFileName!, 'org_logos');
      print("Logo uploaded: $logoUrl");
    }
    if (_bannerBytes != null && _bannerFileName != null) {
      print("Uploading banner...");
      bannerUrl = await _uploadImage(_bannerBytes!, _bannerFileName!, 'org_banners');
      print("Banner uploaded: $bannerUrl");
    }

    final map = {
      'acronym': _controllers['acronym']!.text,
      'name': _controllers['name']!.text,
      'category': _controllers['category']!.text,
      'email': _controllers['email']!.text,
      'mobile': _controllers['mobile']!.text,
      'facebook': _controllers['facebook']!.text,
      'status': _status,
      'logo': logoUrl,
      'banner': bannerUrl,
    };

    print("Submitting organization data: $map");

    try {
      if (_editingUid == null) {
        print("Inserting new organization...");
        final response = await supabase.from('organizations').insert(map).select();

        if (response == null || response is! List || response.isEmpty) {
          print("Insert failed: unexpected response format");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to insert organization.')),
          );
          return;
        }

        print("Insert successful: $response");
      } else {
        print("Updating organization with UID: $_editingUid");
        final response = await supabase.from('organizations').update(map).eq('uid', _editingUid!).select();

        if (response == null || response is! List || response.isEmpty) {
          print("Update failed: unexpected response format");
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
    await Supabase.instance.client.from('organizations').delete().eq('uid', uid);
    await context.read<DataProvider>().fetchOrgs();
  }

  void _loadOrgForEditing(Organization org) {
    _controllers['acronym']!.text = org.acronym;
    _controllers['name']!.text = org.name;
    _controllers['category']!.text = org.category;
    _controllers['email']!.text = org.email;
    _controllers['mobile']!.text = org.mobile;
    _controllers['facebook']!.text = org.facebook;
    _status = org.status;
    _editingUid = org.uid;
    _tabController.animateTo(0);
  }

  Future<void> _pickImage(bool isLogo) async {
    final mediaData = await ImagePickerWeb.getImageAsBytes();
    final info = await ImagePickerWeb.getImageInfo();

    if (mediaData != null && info != null) {
      print("Image picked: ${info.fileName}");
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
    final orgs = context.watch<DataProvider>().orgs ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Organizations', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(true),
                          icon: Icon(Icons.image),
                          label: Text(_logoBytes == null ? 'Pick Logo' : 'Logo Picked'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(false),
                          icon: Icon(Icons.image),
                          label: Text(_bannerBytes == null ? 'Pick Banner' : 'Banner Picked'),
                        ),
                      ),
                    ],
                  ),
                  ..._controllers.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: e.value,
                      decoration: InputDecoration(labelText: e.key.capitalize(), border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  )),
                  SwitchListTile(
                    title: Text('Active Status'),
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  ElevatedButton(
                    onPressed: _submitOrg,
                    child: Text(_editingUid == null ? 'Add Organization' : 'Update Organization'),
                  ),
                ],
              ),
            ),
          ),
          ListView.builder(
            itemCount: orgs.length,
            itemBuilder: (context, index) {
              final org = orgs[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(org.logo ?? '')),
                title: Text(org.name),
                subtitle: Text(org.acronym),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit), onPressed: () => _loadOrgForEditing(org)),
                    IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteOrg(org.uid!)),
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