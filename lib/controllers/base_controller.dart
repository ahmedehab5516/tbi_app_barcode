import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class BaseController extends GetxController {
  late SharedPreferences prefs;

  @override
  void onInit() {
    super.onInit();
    prefs = Get.find<SharedPreferences>();
    getUniqueDeviceId();
  }

  String formatDate(DateTime date) {
    print("11111111111");
    print(DateFormat("yyyy-MMM-dd").format(date));
    return DateFormat("yyyy-MMM-dd").format(date);
  }

  Future<String> getUniqueDeviceId() async {
    String? storedId = prefs.getString("device_id");

    if (storedId != null) {
      return storedId;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id; // ANDROID_ID
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor; // IDFV
    }

    // Fallback to a generated UUID if no hardware ID is found
    deviceId ??= const Uuid().v4();

    // Save locally
    await prefs.setString("device_id", deviceId);

    return deviceId;
  }

  Future<void> cacheStockId(String stockId) async {
    await prefs.setString("stocking_id", stockId);
  }

  String getCachedStockId() {
    return prefs.getString("stocking_id") ?? "";
  }

  Future<void> removeCahcedStockId() async {
    await prefs.remove("stockID");
  }
}
