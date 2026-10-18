import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/app.dart';
import 'package:care_merchant/data/mock/mock_platform_api_client.dart';

void main() {
  testWidgets('CareMerchantApp smoke test', (WidgetTester tester) async {
    final mockClient = MockPlatformApiClient(latency: Duration.zero);

    await tester.pumpWidget(CareMerchantApp(apiClient: mockClient));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app renders Care-Merchant header
    expect(find.text('Care-Merchant'), findsWidgets);
  });
}
