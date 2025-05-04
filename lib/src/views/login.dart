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
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/ccfc.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/logo.png", width: 80, height: 80),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ateneo", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),),
                      Text("Events", style: TextStyle(height: 0.9, color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                width: 380,
                height: 350,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.withOpacity(0.4),
                      Colors.blue[900]?.withAlpha((0.9 * 255).toInt()) ?? Colors.blue.withAlpha((0.9 * 255).toInt()),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("AdDUNET Username", style: TextStyle(color: Colors.white, fontSize: 14,),),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 45,
                            width: 300,
                            child: TextField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Password", style: TextStyle(color: Colors.white, fontSize: 14,),),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 45,
                            width: 300,
                            child: TextField(
                              obscureText: true,
                              obscuringCharacter: "*",
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                    Container(
                      width: 300,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 10,
                          backgroundColor: Colors.grey[350],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () async {
                          await supabase.auth.signInWithOAuth(OAuthProvider.google);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Login with",
                              style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),                       
                            Image.asset("assets/google.png", width: 30, height: 30),                 
                          ],
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}