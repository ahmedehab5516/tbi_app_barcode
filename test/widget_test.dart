import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:tbi_app_barcode/common_files/custom_button.dart';
import 'package:tbi_app_barcode/controllers/warehouse_controller.dart';
import 'package:tbi_app_barcode/screens/warehouse_screen.dart';

// Create a mock class for WarehouseController using a package like Mockito
class MockWarehouseController extends Mock implements WarehouseController {}

void main() {
  group('WarehouseScreen Tests', () {
    late MockWarehouseController mockController;

    setUp(() {
      // Initialize the mock controller
      mockController = MockWarehouseController();
      // Setup GetX to provide the mocked controller
      Get.put<WarehouseController>(mockController);
    });

    testWidgets('WarehouseScreen displays Start Stocking button initially', (WidgetTester tester) async {
      // Mock necessary methods from the controller if any
      when(mockController.showStartButton).thenReturn(true);

      // Build our app and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: WarehouseScreen(),
        ),
      );

      // Verify that the "Start Stocking" button is displayed
      expect(find.byType(MyButton), findsOneWidget);
      expect(find.text('Start Stocking'), findsOneWidget);
    });

    testWidgets('Tapping Start Stocking button calls startStocking', (WidgetTester tester) async {
      // Arrange
      when(mockController.showStartButton).thenReturn(true);
      when(mockController.startStocking()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: WarehouseScreen(),
        ),
      );
      await tester.tap(find.text('Start Stocking'));
      await tester.pump(); // Rebuild the widget after the state change

      // Assert
      verify(mockController.startStocking()).called(1);
    });
  });
}
