import 'package:bloc_test/bloc_test.dart';
import 'package:care_flash/features/auth/bloc/auth_bloc.dart';
import 'package:care_flash/features/auth/bloc/auth_event.dart';
import 'package:care_flash/features/auth/bloc/auth_state.dart';
import 'package:care_flash/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const SignUpScreen(),
      ),
    );
  }

  testWidgets('renders SignUpScreen and dispatches SignUpRequested on submit', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Sign Up')), findsOneWidget);
    expect(find.descendant(of: find.byType(ElevatedButton), matching: find.text('Sign Up')), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    verify(() => mockAuthBloc.add(const SignUpRequested(email: 'test@test.com', password: 'password'))).called(1);
  });
}
