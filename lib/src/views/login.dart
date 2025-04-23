import 'dart:io';

import 'package:cse1_univents/main.dart';
import 'package:cse1_univents/src/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  void _showEmailError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please use your AdDU email account to login.'),
        backgroundColor: Colors.red,
      )
    );
  }

  void _showNotAdminError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are not authorized to access this app.'),
        backgroundColor: Colors.red,
      )
    );
  }

  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final userEmail = session?.user.email ?? '';

      if (session == null) return;

      if (!userEmail.endsWith('@addu.edu.ph')) {
        await supabase.auth.signOut();
        _showEmailError();
        return;
      }

      final response = await supabase
          .from('accounts')
          .select()
          .eq('email', userEmail)
          .maybeSingle();

      final role = response?['role'];

      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
      } else {
        await supabase.auth.signOut();
        _showNotAdminError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        height: screenSize.height,
        width: screenSize.width,
        color: Colors.blue[900],
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 35,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () async {
                    await supabase.auth.signInWithOAuth(OAuthProvider.google);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/google.png", width: 30, height: 30),
                      SizedBox(width: 10),
                      Text("Login"),
                    ],
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}