import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/routing/shells/parent_shell.dart';
import 'package:testing_flutter/core/routing/shells/broker_shell.dart';
import 'package:testing_flutter/core/routing/shells/candidate_shell.dart';
import 'package:testing_flutter/core/routing/shells/agency_admin_shell.dart';
import 'package:testing_flutter/models/user_role.dart';

// Auth screens
import 'package:testing_flutter/screens/auth/role_selection_screen.dart';
import 'package:testing_flutter/screens/auth/login_screen.dart';
import 'package:testing_flutter/screens/auth/otp_verify_screen.dart';
import 'package:testing_flutter/screens/auth/profile_setup_screen.dart';

// Parent screens
import 'package:testing_flutter/screens/home_screen.dart';
import 'package:testing_flutter/screens/search/discovery_screen.dart';
import 'package:testing_flutter/screens/parent/my_brokers_screen.dart';
import 'package:testing_flutter/screens/anuyatra_hub_screen.dart';
import 'package:testing_flutter/screens/parent/parent_profile_screen.dart';

// Broker screens
import 'package:testing_flutter/screens/broker/broker_dashboard_screen.dart';
import 'package:testing_flutter/screens/broker/broker_clients_screen.dart';
import 'package:testing_flutter/screens/broker/broker_profiles_screen.dart';
import 'package:testing_flutter/screens/broker/broker_messages_screen.dart';
import 'package:testing_flutter/screens/broker/broker_own_profile_screen.dart';
import 'package:testing_flutter/screens/broker/profile_create_edit_screen.dart';

// Candidate screens
import 'package:testing_flutter/screens/candidate/candidate_home_screen.dart';
import 'package:testing_flutter/screens/candidate/candidate_shared_profiles_screen.dart';
import 'package:testing_flutter/screens/candidate/candidate_own_profile_screen.dart';

// Agency Admin screens
import 'package:testing_flutter/screens/admin/agency_dashboard_screen.dart';
import 'package:testing_flutter/screens/admin/admin_brokers_screen.dart';
import 'package:testing_flutter/screens/admin/admin_clients_screen.dart';
import 'package:testing_flutter/screens/admin/agency_settings_screen.dart';

// Shared screens
import 'package:testing_flutter/screens/profile/profile_view_screen.dart';
import 'package:testing_flutter/screens/chat/chat_screen.dart';
import 'package:testing_flutter/screens/settings/app_settings_screen.dart';
import 'package:testing_flutter/screens/link_requests_screen.dart';
import 'package:testing_flutter/screens/candidate/link_to_parent_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider with role-based routing
final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes to trigger router refresh, but don't recreate
  // the GoRouter itself. The redirect closure reads auth state on each navigation.
  final authListenable = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) {
    authListenable.value++;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.roleSelectionPath,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,
    redirect: (context, state) {
      // Read auth state fresh on every redirect (NOT captured in closure)
      final authState = ref.read(authProvider);

      final isAuthRoute = state.matchedLocation == RouteNames.roleSelectionPath ||
          state.matchedLocation == RouteNames.loginPath ||
          state.matchedLocation == RouteNames.otpVerifyPath ||
          state.matchedLocation == RouteNames.profileSetupPath;

      // If authenticated, redirect to role-specific home
      if (authState is AuthAuthenticated) {
        if (isAuthRoute) {
          return _homePathForRole(authState.user.role);
        }
        return null;
      }

      // If needs profile, go to profile setup
      if (authState is AuthNeedsProfile) {
        if (state.matchedLocation != RouteNames.profileSetupPath) {
          return RouteNames.profileSetupPath;
        }
        return null;
      }

      // If OTP sent, go to OTP verify
      if (authState is AuthOtpSent) {
        if (state.matchedLocation != RouteNames.otpVerifyPath) {
          return RouteNames.otpVerifyPath;
        }
        return null;
      }

      // If truly unauthenticated (initial state) and not on auth route, go to role selection
      // Don't redirect during transient states (AuthLoading, AuthError) to avoid breaking overlay routes
      if (authState is AuthInitial && !isAuthRoute) {
        return RouteNames.roleSelectionPath;
      }

      return null;
    },
    routes: [
      // ─── AUTH ROUTES ──────────────────────────────
      GoRoute(
        path: RouteNames.roleSelectionPath,
        name: RouteNames.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.otpVerifyPath,
        name: RouteNames.otpVerify,
        builder: (context, state) => const OtpVerifyScreen(),
      ),
      GoRoute(
        path: RouteNames.profileSetupPath,
        name: RouteNames.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ─── PARENT SHELL ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ParentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.parentHomePath,
              name: RouteNames.parentHome,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.parentSearchPath,
              name: RouteNames.parentSearch,
              builder: (context, state) => const DiscoveryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.parentMyBrokersPath,
              name: RouteNames.parentMyBrokers,
              builder: (context, state) => const MyBrokersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.parentAnuyatraPath,
              name: RouteNames.parentAnuyatra,
              builder: (context, state) => const AnuyatraHubScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.parentProfilePath,
              name: RouteNames.parentProfile,
              builder: (context, state) => const ParentProfileScreen(),
            ),
          ]),
        ],
      ),

      // ─── BROKER SHELL ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BrokerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.brokerDashboardPath,
              name: RouteNames.brokerDashboard,
              builder: (context, state) => const BrokerDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.brokerClientsPath,
              name: RouteNames.brokerClients,
              builder: (context, state) => const BrokerClientsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.brokerProfilesPath,
              name: RouteNames.brokerProfiles,
              builder: (context, state) => const BrokerProfilesScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: RouteNames.brokerCreateProfile,
                  builder: (context, state) => const ProfileCreateEditScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.brokerMessagesPath,
              name: RouteNames.brokerMessages,
              builder: (context, state) => const BrokerMessagesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.brokerProfilePath,
              name: RouteNames.brokerProfile,
              builder: (context, state) => const BrokerOwnProfileScreen(),
            ),
          ]),
        ],
      ),

      // ─── CANDIDATE SHELL ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CandidateShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.candidateHomePath,
              name: RouteNames.candidateHome,
              builder: (context, state) => const CandidateHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.candidateSharedPath,
              name: RouteNames.candidateShared,
              builder: (context, state) =>
                  const CandidateSharedProfilesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.candidateAnuyatraPath,
              name: RouteNames.candidateAnuyatra,
              builder: (context, state) => const AnuyatraHubScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.candidateProfilePath,
              name: RouteNames.candidateProfile,
              builder: (context, state) => const CandidateOwnProfileScreen(),
            ),
          ]),
        ],
      ),

      // ─── AGENCY ADMIN SHELL ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AgencyAdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.adminDashboardPath,
              name: RouteNames.adminDashboard,
              builder: (context, state) => const AgencyDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.adminBrokersPath,
              name: RouteNames.adminBrokers,
              builder: (context, state) => const AdminBrokersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.adminClientsPath,
              name: RouteNames.adminClients,
              builder: (context, state) => const AdminClientsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.adminSettingsPath,
              name: RouteNames.adminSettings,
              builder: (context, state) => const AgencySettingsScreen(),
            ),
          ]),
        ],
      ),

      // ─── SHARED ROUTES (overlay on any shell) ──────────────────
      GoRoute(
        path: RouteNames.profileViewPath,
        name: RouteNames.profileView,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileViewScreen(),
      ),
      GoRoute(
        path: RouteNames.chatPath,
        name: RouteNames.chat,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: RouteNames.appSettingsPath,
        name: RouteNames.appSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.linkRequestsPath,
        name: RouteNames.linkRequests,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LinkRequestsScreen(),
      ),
      GoRoute(
        path: RouteNames.linkToParentPath,
        name: RouteNames.linkToParent,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LinkToParentScreen(),
      ),
    ],
  );
});

/// Map UserRole to the home path for that role
String _homePathForRole(UserRole role) {
  switch (role) {
    case UserRole.parent:
      return RouteNames.parentHomePath;
    case UserRole.broker:
      return RouteNames.brokerDashboardPath;
    case UserRole.candidate:
      return RouteNames.candidateHomePath;
    case UserRole.agencyAdmin:
      return RouteNames.adminDashboardPath;
  }
}
