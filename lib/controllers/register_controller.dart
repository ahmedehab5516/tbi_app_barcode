import 'dart:convert';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tbi_app_barcode/controllers/base_controller.dart';

import '../common_files/snack_bar.dart';
import '../models/pos_data.dart';
import '../models/store_details.dart';
import '../screens/warehouse_screen.dart';

class RegisterController extends BaseController {
  late TextEditingController name;
  late TextEditingController phoneNumber;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Rx<StoreData?> selectedStore = Rx<StoreData?>(null);
  final stores = <StoreData>[].obs;
  final RxBool storesLoaded = false.obs;
  RxString responseMessage = ''.obs;
  bool submitButtonPressed = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    name = TextEditingController();
    phoneNumber = TextEditingController();
    await getAllStores();
  }

  void updateSelectedValue(StoreData store) {
    selectedStore.value = store;
  }

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
          stores.add(StoreData(
              id: store.id, name: store.name)); // Add the full StoreData object
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

  Future<void> postPosData() async {
    if (name.text.isEmpty ||
        phoneNumber.text.isEmpty ||
        selectedStore.value == null) {
      SnackbarHelper.showFailure(
          "Error", "Please fill all the required fields.");
      return;
    }

    final Uri url =
        Uri.parse("https://visa-api.ck-report.online/api/Store/AddPosRequest");

    try {
      // Use your unique device id (here hard-coded for example purposes).
      String deviceId = await getUniqueDeviceId();
      print("Device ID: $deviceId");

      final Map<String, dynamic> body = PosData(
        posSerial: deviceId.trim().toLowerCase(),
        name: name.text.trim().toLowerCase(),
        phone: phoneNumber.text.trim().toLowerCase(),
        storeId: selectedStore.value!.id.toString(),
      ).toJson();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Set initial response message and mark submission as pressed.
        responseMessage.value = jsonDecode(response.body)['message'];
        submitButtonPressed = true;
        update();

        // Start polling for the request's approval status.
        listenForPosApproval(deviceId);
      } else {
        throw Exception(
            "Failed to post POS data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      SnackbarHelper.showFailure("Error", "Error posting POS data: $e");
      throw Exception("Error posting POS data: $e");
    }

    submitButtonPressed = true;
    update();
  }

  /// Polls the backend periodically for the POS request status.
  /// Adjust the URL and response keys as required by your API.
  Future<void> listenForPosApproval(String posSerial) async {
    // Poll every 5 seconds.
    const Duration pollingInterval = Duration(seconds: 5);

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
            // Stop polling once a final status is reached.
            timer.cancel();
            Get.off(WarehouseScreen());
            update();
          } else if (approvalStatus == 0) {
            responseMessage.value = statusData["message"];
          }
        } else {
          print("Status check failed: ${statusResponse.statusCode}");
        }
      } catch (e) {
        print("Error checking POS request status: $e");
      }
    });
  }
}
