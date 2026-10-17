import 'package:care_flash_core/auth.dart';
import 'package:test/test.dart';

void main() {
  test('AuthUser props', () {
    const user = AuthUser(id: '1', email: 'test@example.com');
    expect(user.props, ['1', 'test@example.com', null]);
  });
}
