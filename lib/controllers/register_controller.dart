import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../common_files/snack_bar.dart';
import '../models/store_details.dart';
import '../screens/parent_category_screen.dart';
import 'base_controller.dart';

class RegisterController extends BaseController {
  late TextEditingController name;
  late TextEditingController phoneNumber;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Rx<StoreData?> selectedStore = Rx<StoreData?>(null);
  final stores = <StoreData>[].obs;
  final RxBool storesLoaded = false.obs;
  RxString responseMessage = ''.obs;
  bool submitButtonPressed = false;
  RxBool isLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    name = TextEditingController();
    phoneNumber = TextEditingController();
    await getAllStores(); // Load stores here
  }

  // Update selected store value
  void updateSelectedValue(StoreData store) {
    selectedStore.value = store;
  }

  // Fetch all stores
  Future<void> getAllStores() async {
    final Uri url =
        Uri.parse("https://visa-api.ck-report.online/api/Store/loadStores");

    try {
      storesLoaded.value = false;
      final response = await http.get(url);

      if (response.statusCode == 200) {
        StoreDetails loadStores =
            StoreDetails.fromJson(jsonDecode(response.body));

        stores.clear();
        for (var store in loadStores.data) {
          stores.add(StoreData(id: store.id, name: store.name));
        }
        storesLoaded.value = true;
      } else {
        storesLoaded.value = false;
        throw Exception(
            "Failed to load stores. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      storesLoaded.value = false;
      throw Exception("Error fetching stores: $e");
    }
  }

  // Post POS data
  Future<void> postPosData() async {
    if (!formKey.currentState!.validate()) return;

    if (name.text.isEmpty || phoneNumber.text.isEmpty) {
      SnackbarHelper.showFailure(
          "Error", "Please fill all the required fields.");
      return;
    }

    isLoading.value = true;

    final Uri url =
        Uri.parse("https://visa-api.ck-report.online/api/Store/AddPosRequest");
    try {
      await prefs.setString("store", jsonEncode(selectedStore.value));
      String deviceId = await getUniqueDeviceId();
      final Map<String, dynamic> body = {
        "posSerial": deviceId.trim().toLowerCase(),
        "name": name.text.trim().toLowerCase(),
        "phone": phoneNumber.text.trim().toLowerCase(),
        "storeId": selectedStore.value?.id ?? "0",
        // "storeId": 1
      };

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody != null && responseBody.containsKey('message')) {
          responseMessage.value = responseBody['message'];
        }
        submitButtonPressed = true;
        isLoading.value = false;

        // Poll for approval status
        listenForPosApproval(deviceId);
      } else {
        throw Exception(
            "Failed to post POS data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      isLoading.value = false;
      throw Exception("Error posting POS data: $e");
    }
  }

  // Listen for POS approval status
  Future<void> listenForPosApproval(String posSerial) async {
    const Duration pollingInterval = Duration(seconds: 2);

    Timer.periodic(pollingInterval, (Timer timer) async {
      final Uri statusUrl = Uri.parse(
          "https://visa-api.ck-report.online/api/Store/posLogin?posSerial=$posSerial");
      try {
        final statusResponse = await http.get(statusUrl);
        if (statusResponse.statusCode == 200) {
          final Map<String, dynamic> statusData =
              jsonDecode(statusResponse.body);

          final int approvalStatus = statusData["status"];
          if (approvalStatus == 1) {
            responseMessage.value = statusData["message"];
            timer.cancel(); // Stop polling once approved
            Get.off(() => ParentCategoryScreen());
          } else if (approvalStatus == 0) {
            responseMessage.value = statusData["message"];
          }
        } else {
          throw Exception("Status check failed: ${statusResponse.statusCode}");
        }
      } catch (e) {
        throw Exception("Error checking POS request status: $e");
      }
    });
  }
}
