import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tbi_app_barcode/common_files/text_field.dart';
import 'package:tbi_app_barcode/controllers/register_controller.dart';

import '../common_files/custom_button.dart';
import '../models/store_details.dart';

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
          width: double.infinity,
          height: 50.0,
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Form(
          key: _regController.formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyTextField(
                hintText: "Name",
                controller: _regController.name,
              ),
              const SizedBox(height: 10.0),
              MyTextField(
                hintText: "Phone Number",
                controller: _regController.phoneNumber,
              ),
              const SizedBox(height: 20.0),
              _buildStoresDropDownMenu(context, _regController),
              const SizedBox(height: 30.0),
              MyButton(
                  onTap: () => _regController.postPosData(), label: "Submit"),
              const SizedBox(height: 30.0),
              GetBuilder<RegisterController>(
                builder: (controller) => Visibility(
                  visible: _regController.submitButtonPressed,
                  child: Obx(() => Text(_regController.responseMessage.value)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoresDropDownMenu(
      BuildContext context, RegisterController controller) {
    return Center(
      child: Obx(() {
        if (!controller.storesLoaded.value) {
          return const CircularProgressIndicator();
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: DropdownButtonFormField<StoreData>(
            // Change type to StoreData
            alignment: AlignmentDirectional.center,
            decoration: const InputDecoration(
              labelText: 'Select Store',
              border: OutlineInputBorder(),
            ),
            value: controller.selectedStore.value,
            onChanged: (StoreData? newValue) {
              // Now receives StoreData directly
              if (newValue != null) {
                controller.updateSelectedValue(newValue);
              }
            },
            items: controller.stores
                .map<DropdownMenuItem<StoreData>>((StoreData store) {
              return DropdownMenuItem<StoreData>(
                value: store, // Store entire StoreData object as value
                child: Text(
                  store.name,
                  style: const TextStyle(fontSize: 15.0),
                ), // Display store name in dropdown
              );
            }).toList(),
            isExpanded: true,
            iconSize: 24.0,
            iconEnabledColor: Colors.black,
          ),
        );
      }),
    );
  }
}
