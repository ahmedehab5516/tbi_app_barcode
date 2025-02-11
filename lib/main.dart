import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tbi_app_barcode/other_files/dependency_injection.dart';
import 'package:tbi_app_barcode/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dependencyInjection();

  runApp(const TbiApp());
}

class TbiApp extends StatelessWidget {
  const TbiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}
