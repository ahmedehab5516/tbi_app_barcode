import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tbi_app_barcode/widgets/loading_indecator.dart';

import '../common_files/custom_button.dart';
import '../common_files/text_field.dart';
import '../controllers/register_controller.dart';
import '../models/store_details.dart'; // Import the model for stores

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final _regController = Get.find<RegisterController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Image.asset(
          "assets/images/idpgH2alr7_1738673273412.png",
          width: 150.0,
          height: 50.0,
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        return Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _regController.formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20.0),

                        // Name Field with animation
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: MyTextField(
                            hintText: "Enter Name",
                            controller: _regController.name,
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // Phone Number Field with animation
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: MyTextField(
                            hintText: "Enter Phone Number",
                            controller: _regController.phoneNumber,
                            keyboardType: TextInputType.phone,
                            validator: (value) => phoneNumberValidator(value),
                          ),
                        ),

                        const SizedBox(height: 20.0),

                        // Store Selection Dropdown
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(
                        //       horizontal: 16.0, vertical: 20.0),
                        //   child: Obx(() {
                        //     if (!_regController.storesLoaded.value) {
                        //       return const CircularProgressIndicator();
                        //     } else if (!_regController.isConnected.value) {
                        //       return Container(
                        //         padding: const EdgeInsets.all(10),
                        //         decoration: BoxDecoration(
                        //           color: Colors.red,
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         child: const Text(
                        //           "You are offline. Some features may be limited.",
                        //           style: TextStyle(color: Colors.white),
                        //           textAlign: TextAlign.center,
                        //         ),
                        //       );
                        //     }

                        //     return buildStoreSelectionDrobDownMenu();
                        //   }),
                        // ),

                        const SizedBox(height: 20.0),

                        // Submit Button with animation
                        AnimatedPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          duration: const Duration(milliseconds: 300),
                          child: MyButton(
                            onTap: () async =>
                                await _regController.postPosData(),
                            label: "Submit",
                            padding: 16.0,
                            backgroundColor: Colors.redAccent,
                            borderRadius: 12.0,
                          ),
                        ),
                        const SizedBox(height: 30.0),

                        // Response message or loading state with animation
                        GetBuilder<RegisterController>(builder: (controller) {
                          return Visibility(
                            visible: _regController.submitButtonPressed,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Obx(() =>
                                  controller.responseMessage.value.isNotEmpty
                                      ? Text(
                                          controller.responseMessage.value,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const BuildLoadingIndecator()),
                            ),
                          );
                        }),

                        Obx(
                          () => !_regController.isConnected.value
                              ? Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "You are offline. Some features may be limited.",
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _regController.isLoading.value
                ? Center(
                    child: BuildLoadingIndecator(),
                  )
                : SizedBox.shrink(),
          ],
        );
      }),
    );
  }

  DropdownButtonFormField<StoreData> buildStoreSelectionDrobDownMenu() {
    return DropdownButtonFormField<StoreData>(
      decoration: const InputDecoration(
        labelText: 'Select Store',
        labelStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      ),
      value: _regController.selectedStore.value,
      onChanged: (StoreData? newValue) {
        if (newValue != null) {
          _regController.updateSelectedValue(newValue);
        }
      },
      items: _regController.stores
          .map<DropdownMenuItem<StoreData>>((StoreData store) {
        return DropdownMenuItem<StoreData>(
          value: store,
          child: Text(
            store.name,
            style: const TextStyle(fontSize: 16.0),
          ),
        );
      }).toList(),
      isExpanded: true,
      iconSize: 24.0,
      iconEnabledColor: Colors.black,
    );
  }

  String? phoneNumberValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    final regex = RegExp(r'^01[0-9]{9}$');
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }
}
