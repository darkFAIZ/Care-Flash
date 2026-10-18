import 'package:flutter/material.dart';
import 'app.dart';
import 'data/mock/mock_platform_api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final mockClient = MockPlatformApiClient();
  runApp(CareMerchantApp(apiClient: mockClient));
}
