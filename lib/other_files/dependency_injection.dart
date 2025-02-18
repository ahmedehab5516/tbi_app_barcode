import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/category_conroller.dart';
import '../controllers/register_controller.dart';
import '../controllers/warehouse_controller.dart';

Future<void> dependencyInjection() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(sharedPreferences, permanent: true);


  // Inject controllers after SharedPreferences is ready
  Get.put<RegisterController>(RegisterController());
  Get.put<CategoryController>(CategoryController());

  Get.lazyPut<WarehouseController>(() => WarehouseController(), fenix: true);
}
