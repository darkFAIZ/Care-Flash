import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/network/platform_api_client.dart';
import 'data/mock/mock_platform_api_client.dart';
import 'features/active_session/domain/entities/active_session.dart';
import 'features/active_session/presentation/bloc/active_session_bloc.dart';
import 'features/active_session/presentation/screens/active_session_screen.dart';
import 'features/arrival_verification/presentation/bloc/arrival_verification_bloc.dart';
import 'features/arrival_verification/presentation/screens/arrival_verification_screen.dart';
import 'features/auth_onboarding/presentation/bloc/auth_bloc.dart';
import 'features/auth_onboarding/presentation/screens/login_screen.dart';
import 'features/auth_onboarding/presentation/screens/verification_status_screen.dart';
import 'features/availability/presentation/bloc/availability_bloc.dart';
import 'features/availability/presentation/screens/caregiver_home_screen.dart';
import 'features/earnings/presentation/bloc/earnings_bloc.dart';
import 'features/earnings/presentation/screens/earnings_dashboard_screen.dart';
import 'features/matching/presentation/bloc/matching_bloc.dart';
import 'features/matching/presentation/widgets/incoming_offer_dialog.dart';
import 'features/ride_transit/domain/entities/grab_ride_info.dart';

class CareMerchantApp extends StatelessWidget {
  final PlatformApiClient apiClient;

  const CareMerchantApp({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PlatformApiClient>.value(value: apiClient),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(apiClient: apiClient)..add(const CheckAuthRequested()),
          ),
          BlocProvider<AvailabilityBloc>(
            create: (ctx) => AvailabilityBloc(apiClient: apiClient),
          ),
          BlocProvider<MatchingBloc>(
            create: (ctx) => MatchingBloc(apiClient: apiClient),
          ),
          BlocProvider<ArrivalVerificationBloc>(
            create: (ctx) => ArrivalVerificationBloc(apiClient: apiClient),
          ),
          BlocProvider<ActiveSessionBloc>(
            create: (ctx) => ActiveSessionBloc(apiClient: apiClient),
          ),
          BlocProvider<EarningsBloc>(
            create: (ctx) => EarningsBloc(apiClient: apiClient),
          ),
        ],
        child: MaterialApp(
          title: 'Care-Merchant',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const CareMerchantRoot(),
        ),
      ),
    );
  }
}

class CareMerchantRoot extends StatefulWidget {
  const CareMerchantRoot({super.key});

  @override
  State<CareMerchantRoot> createState() => _CareMerchantRootState();
}

class _CareMerchantRootState extends State<CareMerchantRoot> {
  int _currentTabIndex = 0;
  AcceptedTrip? _activeTrip;
  ActiveSession? _currentSession;
  bool _isInActiveSession = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              context
                  .read<AvailabilityBloc>()
                  .add(LoadAvailability(state.profile));
              context.read<EarningsBloc>().add(const FetchEarningsRequested());
            }
          },
        ),
        BlocListener<MatchingBloc, MatchingState>(
          listener: (context, state) {
            if (state is OfferIncoming) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => BlocProvider.value(
                  value: context.read<MatchingBloc>(),
                  child: BlocBuilder<MatchingBloc, MatchingState>(
                    builder: (ctx, matchState) {
                      if (matchState is OfferIncoming) {
                        return IncomingOfferDialog(
                          offer: matchState.offer,
                          secondsRemaining: matchState.secondsRemaining,
                          onAccept: () {
                            Navigator.of(dialogContext).pop();
                            context.read<MatchingBloc>().add(
                                  AcceptOfferRequested(
                                    matchState.offer.requestReference,
                                  ),
                                );
                          },
                          onDecline: () {
                            Navigator.of(dialogContext).pop();
                            context.read<MatchingBloc>().add(
                                  DeclineOfferRequested(
                                    matchState.offer.requestReference,
                                  ),
                                );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              );
            } else if (state is OfferAccepted) {
              setState(() {
                _activeTrip = state.trip;
                _isInActiveSession = false;
                _currentSession = null;
              });
            } else if (state is OfferTimeout || state is OfferDeclined) {
              // Dialog dismissed
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authState is NeedsVerification) {
            return VerificationStatusScreen(profile: authState.profile);
          }

          if (authState is! Authenticated) {
            return const LoginScreen();
          }

          // Active Trip flow overrides navigation
          if (_activeTrip != null) {
            if (_isInActiveSession && _currentSession != null) {
              return ActiveSessionScreen(
                session: _currentSession!,
                onSessionFinished: () {
                  setState(() {
                    _activeTrip = null;
                    _currentSession = null;
                    _isInActiveSession = false;
                  });
                  context
                      .read<EarningsBloc>()
                      .add(const FetchEarningsRequested());
                },
              );
            } else {
              return ArrivalVerificationScreen(
                trip: _activeTrip!,
                onVerificationComplete: () async {
                  final session = await context
                      .read<PlatformApiClient>()
                      .startSession(_activeTrip!.bookingId);
                  if (context.mounted) {
                    context
                        .read<ActiveSessionBloc>()
                        .add(StartActiveSession(session));
                    setState(() {
                      _currentSession = session;
                      _isInActiveSession = true;
                    });
                  }
                },
              );
            }
          }

          // Main Tabs Screen
          return Scaffold(
            body: IndexedStack(
              index: _currentTabIndex,
              children: const [
                CaregiverHomeScreen(),
                EarningsDashboardScreen(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: (index) {
                setState(() => _currentTabIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Earnings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
