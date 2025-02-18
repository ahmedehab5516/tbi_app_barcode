import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/user_auth_data.dart';
import 'category_screen.dart';
import 'register_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  late Future<Widget> _screenFuture;
  SharedPreferences? _prefs; // Make nullable
  bool _isChecking = true;  // Track if the serial check is in progress

  @override
  void initState() {
    super.initState();
    _screenFuture = _initAndDetermineScreen();
  }

  Future<Widget> _initAndDetermineScreen() async {
    _prefs = await SharedPreferences.getInstance();
    return _determineScreen();
  }

  Future<UserAuth?> _posLogin(String posSerial) async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://visa-api.ck-report.online/api/Store/posLogin?posSerial=$posSerial"),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("Login Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        return UserAuth.fromJson(decoded);
      }
      return null;
    } catch (e, stack) {
      debugPrint("Login Error: $e\n$stack");
      return null;
    }
  }

  Future<Widget> _determineScreen() async {
    try {
      final deviceId = _prefs?.getString("device_id"); 
    
      debugPrint("Device ID: $deviceId");

      if (deviceId == null || deviceId.isEmpty) {
        return RegisterScreen();
      }

      final user = await _posLogin(deviceId);
      bool isValid = user?.data?.serial.toLowerCase() == deviceId.toLowerCase();

      if (user!.message == "pos serial exist before !!") {
        isValid = true;
      }

      debugPrint("User Valid: $isValid");

      // After the check is done, hide the loading spinner and return the appropriate screen
      setState(() {
        _isChecking = false;
      });

      return isValid ? CategoryScreen() : RegisterScreen();
    } catch (e, stack) {
      debugPrint("Screen Determination Error: $e\n$stack");
      setState(() {
        _isChecking = false;
      });
      return RegisterScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _screenFuture,
      builder: (context, snapshot) {
        // Show loading spinner while checking the serial
        if (_isChecking) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If an error occurs during screen determination
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint("FutureBuilder Error: ${snapshot.error}");
          return const Scaffold(
            body: Center(child: Text("Error initializing application")),
          );
        }

        // Return the screen after the check is completed
        return snapshot.data ?? RegisterScreen();
      },
    );
  }
}
