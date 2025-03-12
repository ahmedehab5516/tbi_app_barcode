import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/loading_indecator.dart';

import '../models/user_auth_data.dart';
import 'parent_category_screen.dart';
import 'register_screen.dart';
import 'warehouse_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<Widget> _screenFuture;
  SharedPreferences? _prefs; // Make nullable
  bool isChecking = true;

  @override
  void initState() {
    super.initState();
    _screenFuture = _initAndDetermineScreen();
  }

  Future<Widget> _initAndDetermineScreen() async {
    _prefs = Get.find<SharedPreferences>();
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

      // If device_id is missing, clear SharedPreferences and return RegisterScreen.
      if (deviceId == null || deviceId.isEmpty) {
        await _prefs?.clear();
        return RegisterScreen();
      }

      // Check for store and catCode (including empty string check)
      String? storeJson = _prefs?.getString("store");
      String? parentCatCode = _prefs?.getString("parentCatCode");

      // Retrieve the start button flag as a boolean.
      // If not set, default to true.
      bool showStartButton = _prefs?.getBool("showStartButton") ?? true;

      // If the start button flag is false, navigate directly to WarehouseScreen.
      if (!showStartButton) {
        return WarehouseScreen();
      }

      // If store or catCode are missing, clear SharedPreferences and return RegisterScreen.
      if (storeJson == null ||
          storeJson.isEmpty ||
          parentCatCode == null ||
          parentCatCode.isEmpty) {
        await _prefs?.clear();
        return RegisterScreen();
      }

      // Proceed with login/authentication logic.
      final user = await _posLogin(deviceId);
      if (user == null) {
        await _prefs?.clear();
        return RegisterScreen();
      }

      bool isValid = user.data?.serial.toLowerCase() == deviceId.toLowerCase();
      if (user.message == "pos serial exist before !!") {
        isValid = true;
      }
      debugPrint("User Valid: $isValid");

      // Hide the loading spinner.
      setState(() {
        isChecking = false;
      });

      return isValid ? ParentCategoryScreen() : RegisterScreen();
    } catch (e, stack) {
      debugPrint("Screen Determination Error: $e\n$stack");
      setState(() {
        isChecking = false;
      });
      await _prefs?.clear();
      return RegisterScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _screenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: BuildLoadingIndecator(),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint("FutureBuilder Error: ${snapshot.error}");
          return const Scaffold(
            body: Center(child: Text("Error initializing application")),
          );
        }
        return snapshot.data ?? RegisterScreen();
      },
    );
  }
}
