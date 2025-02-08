class LoadStores {
  int? status;
  List<Data>? data;

  LoadStores({this.status, this.data});

  LoadStores.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  String? name;

  Data({this.id, this.name});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}











// send data using dio . i like http

// Future<void> sendData(String barcode, int quantity) async {
//   final dio = Dio();

//   // Enable detailed logging for debugging
//   dio.interceptors.add(LogInterceptor(
//     request: true,
//     requestHeader: true,
//     requestBody: true,
//     responseHeader: true,
//   ));

//   try {
//     final response = await dio.post(
//       'https://visa-api.ck-report.online/api/Store/warehouseCheck',
//       data: [
//         {
//           "barcode": barcode,
//           "quantity": quantity,
//           "stockDate": "2025-Jan-01",
//           "status": 0
//         }
//       ],
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': '*/*',
//           'Connection': 'keep-alive',
//           'posserial': '123456789'
//         },
//       ),
//     );

//     print('Success: ${response.data}');
//   } on DioException catch (e) {
//     print('Error: ${e.response?.statusCode} - ${e.response?.data}');
//     print('TraceId: ${e.response?.data?['traceId']}'); // Ensure safe access
//   }
// }
















// // ignore_for_file: non_constant_identifier_names

// import 'dart:convert';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:tbi_app/controllers/base_controller.dart';
// import 'package:tbi_app/models/product_data.dart';
// import 'package:tbi_app/models/warehouse.dart';
// import 'package:http/http.dart' as http;

// class WarehouseController extends BaseController {
//   final RxMap<String, int> productQuantity = <String, int>{}.obs;
//   final Map<String, TextEditingController> quantityControllers = {};
//   bool showStartButton = true;
//   final int STATUS_NO_STOCK = 1;
//   final int STATUS_STOCK = 0;

//   List<Product> allProducts = [];

//   @override
//   void onInit() {
//     super.onInit();
//     _restoreStockData(); // Restore cached data when app starts
//   }

//   void updateQuantity(String barcode, int newQuantity) {
//     productQuantity[barcode] = newQuantity;
//     quantityControllers[barcode]?.text = newQuantity.toString();
//     _cacheStockData(); // Cache data after every update
//   }

//   void initializeController(String barcode) {
//     if (!quantityControllers.containsKey(barcode)) {
//       quantityControllers[barcode] = TextEditingController(
//         text: productQuantity[barcode]?.toString() ?? '0',
//       );
//     }
//   }

//   void onScannedFunction(String barcodeValue, BuildContext context) {
//     if (productQuantity.containsKey(barcodeValue)) {
//       updateQuantity(barcodeValue, productQuantity[barcodeValue]! + 1);
//     } else {
//       productQuantity[barcodeValue] = 1;
//       initializeController(barcodeValue);
//       _cacheStockData(); // Cache the scanned product
//     }

//     sendData(barcodeValue, productQuantity[barcodeValue]!);
//   }

//   Future<void> endStocking() async {
//     try {
//       final List<WarehouseStockProduct> allProducts =
//           productQuantity.entries.map((entry) {
//         return WarehouseStockProduct(
//           barcode: entry.key,
//           quantity: entry.value,
//           stockDate: _retrieveStockingDate(),
//           status: STATUS_STOCK,
//         );
//       }).toList();

//       // await sendDataBatch(allProducts);
      

//       productQuantity.clear();
//       quantityControllers.clear();
//       _clearCachedStockData(); // Clear cache after successful upload
//     } catch (e) {
//       Get.snackbar("Error", "Failed to complete stocking: ${e.toString()}");
//       rethrow;
//     }

//     showStartButton = true;
//     update();
//   }

//   Future<void> startStocking() async {
//     showStartButton = false;
//     update();
//     _cacheStockingDate();
//   }

//   Future<void> sendData(String barcode, int quantity) async {
//     final dio = Dio();

//     // Enable detailed logging for debugging
//     dio.interceptors.add(LogInterceptor(
//       request: true,
//       requestHeader: true,
//       requestBody: true,
//       responseHeader: true,
//     ));

//     try {
//       final response = await dio.post(
//         'https://visa-api.ck-report.online/api/Store/warehouseCheck',
//         data: [
//           {
//             "barcode": barcode,
//             "quantity": quantity,
//             "stockDate": "2025-Jan-01",
//             "status": 0
//           }
//         ],
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Accept': '*/*',
//             'Connection': 'keep-alive',
//             'posserial': '123456789'
//           },
//         ),
//       );
//     } catch (e) {
//       throw Exception("error $e");
//     }
//   }

//   Future<void> sendDataBatch(List<WarehouseStockProduct> products) async {
//     final Uri url =
//         Uri.parse('https://visa-api.ck-report.online/api/Store/warehouseCheck');

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': '*/*',
//           'Connection': 'keep-alive',
//           'posserial': '123456789'
//         },
//         body: jsonEncode(products.map((p) => p.toJson()).toList()),
//       );

//       if (response.statusCode != 200) {
//         throw Exception("Batch upload failed: ${response.statusCode}");
//       }
//     } catch (e) {
//       throw Exception("Batch upload error: $e");
//     }
//   }

//   String getProductName(String barcode) {
//     // Use firstWhereOrNull for safer lookup
//     final product =
//         allProducts.firstWhereOrNull((p) => p.itemLookupCode == barcode);
//     return product?.description ?? "Product Not Found";
//   }

//   /// ---- LOCAL CACHING METHODS ----

//   /// Cache stock data to local memory
//   Future<void> _cacheStockData() async {
//     final stockData = productQuantity.map((key, value) => MapEntry(key, value));
//     await prefs.setString("cached_stock_data", jsonEncode(stockData));
//   }

//   /// Restore stock data when the app restarts
//   Future<void> _restoreStockData() async {
//     final String? cachedData = prefs.getString("cached_stock_data");

//     if (cachedData != null) {
//       final Map<String, dynamic> decodedData = jsonDecode(cachedData);
//       productQuantity.value =
//           decodedData.map((key, value) => MapEntry(key, value as int));

//       productQuantity.keys.forEach(initializeController);
//       showStartButton = false; // Prevent resetting if stocking was in progress
//       update();
//     }
//   }

//   /// Clear cached stock data after successful submission
//   Future<void> _clearCachedStockData() async {
//     await prefs.remove("cached_stock_data");
//     await prefs.remove("stocking_date");
//   }

//   /// Cache the start date of stocking
//   Future<void> _cacheStockingDate() async {
//     await prefs.setString("stocking_date", DateTime.now().toIso8601String());
//   }

//   /// Retrieve the cached stocking date
//   String _retrieveStockingDate() {
//     return prefs.getString("stocking_date") ?? DateTime.now().toIso8601String();
//   }
// }




