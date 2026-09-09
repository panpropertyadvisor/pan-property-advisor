// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';

// Login & General Pages
import 'pages/login_page.dart';
import 'pages/welcome_page.dart';
import 'pages/about_you_page.dart';
import 'pages/know_your_finances_page.dart';
import 'pages/coming_soon_page.dart';
import 'pages/payment_page.dart';
import 'pages/passcode_login_page.dart';

// Investor Pages
import 'pages/investor_dashboard.dart';
import 'pages/investor_about_you_page.dart';
import 'pages/investor_terms_page.dart';

// Mortgage Broker Pages
import 'pages/mortgage_broker_intro_page.dart';
import 'pages/mortgage_broker_about_you_page.dart';
import 'pages/mortgage_broker_details_page.dart';
import 'pages/mortgage_broker_preview_page.dart';
import 'pages/mortgage_broker_dashboard.dart';

// Buyers Agent Pages
import 'pages/buyers_agent_intro_page.dart';
import 'pages/buyers_agent_about_you_page.dart';
import 'pages/buyers_agent_details_page.dart';
import 'pages/buyers_agent_preview_page.dart';
import 'pages/buyers_agent_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe initialization
  Stripe.publishableKey =
      "pk_test_51TiCgaHFW23OY0ENEcTGlxKdb8tJ5E569Dh5VVooDl4Pnc5aP1j1pjOzOjQvOeJU6lzvE6Cg32ayNi4N7fnemPWq00J18dgtAw";
  await Stripe.instance.applySettings();

  // Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PanPropertyAdvisorApp());
}

/// Robust splash/logo page that displays a logo before navigating to [next].
class HomeLogoPage extends StatefulWidget {
  final Widget next;
  final Duration delay;

  const HomeLogoPage({
    required this.next,
    this.delay = const Duration(milliseconds: 900),
    super.key,
  });

  @override
  State<HomeLogoPage> createState() => _HomeLogoPageState();
}

class _HomeLogoPageState extends State<HomeLogoPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
        'HomeLogoPage: initState, will navigate in ${widget.delay.inMilliseconds}ms to ${widget.next.runtimeType}');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(widget.delay);
      if (!mounted) return;
      if (!_navigated) {
        _navigated = true;

        FocusScope.of(context).unfocus();

        debugPrint('HomeLogoPage: navigating to ${widget.next.runtimeType}');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.next),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Image.asset(
                'assets/logo/logo2.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const FlutterLogo(size: 120),
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class PanPropertyAdvisorApp extends StatefulWidget {
  const PanPropertyAdvisorApp({super.key});

  @override
  State<PanPropertyAdvisorApp> createState() => _PanPropertyAdvisorAppState();
}

class _PanPropertyAdvisorAppState extends State<PanPropertyAdvisorApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  /// Reads auth + local prefs + Firestore and decides the initial route.
  Future<Map<String, dynamic>> _readState(User? user) async {
    final prefs = await SharedPreferences.getInstance();

    final String? roleLocal = prefs.getString('role');
    final bool paidLocal = prefs.getBool('paid') ?? false;
    final bool profileCompletedLocal =
        prefs.getBool('profileCompleted') ?? false;
    final String? passcodeLocal = prefs.getString('userPasscode');

    final bool hasLocalSession =
        (roleLocal != null && roleLocal.isNotEmpty) ||
            (passcodeLocal != null && passcodeLocal.isNotEmpty);

    // ========== DEBUG START ==========
    debugPrint('========== _readState DEBUG ==========');
    debugPrint('DEBUG USER: $user');
    debugPrint('DEBUG USER UID: ${user?.uid}');
    debugPrint('DEBUG PREFS paid: $paidLocal');
    debugPrint('DEBUG PREFS role: $roleLocal');
    debugPrint('DEBUG PREFS profileCompleted: $profileCompletedLocal');
    debugPrint('DEBUG PREFS passcode present: ${passcodeLocal != null}');
    debugPrint('DEBUG hasLocalSession: $hasLocalSession');
    // ========== DEBUG END ==========

    if (user == null) {
      debugPrint(
          '→ Decision: user is null | hasLocalSession=$hasLocalSession → '
          '${hasLocalSession ? "LoginPage" : "WelcomePage"}');
      return {
        'role': roleLocal,
        'paid': paidLocal,
        'profileCompleted': profileCompletedLocal,
        'userExists': false,
        'hasLocalSession': hasLocalSession,
      };
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      debugPrint('DEBUG FIRESTORE doc exists: ${doc.exists}');
      debugPrint('DEBUG FIRESTORE data: ${doc.data()}');

      if (!doc.exists) {
        debugPrint('Firestore doc missing -> Clearing local cache and routing to WelcomePage');
        await prefs.clear(); // Clear cached session
        await FirebaseAuth.instance.signOut();
        return {
          'role': null,
          'paid': false,
          'profileCompleted': false,
          'userExists': false,
          'hasLocalSession': false, // Forces routing to WelcomePage
        };
      }

      final data = doc.data()!;
      final String? role = (data['role'] as String?) ?? roleLocal;
      final bool paid = (data['paid'] as bool?) ?? paidLocal;
      final bool profileCompleted =
          (data['profileCompleted'] as bool?) ?? profileCompletedLocal;

      debugPrint(
          '→ Final decision values: role=$role | paid=$paid | profileCompleted=$profileCompleted');

      return {
        'role': role,
        'paid': paid,
        'profileCompleted': profileCompleted,
        'userExists': true,
        'hasLocalSession': true,
      };
    } catch (e) {
      debugPrint('Error reading Firestore user doc: $e');
      return {
        'role': roleLocal,
        'paid': paidLocal,
        'profileCompleted': profileCompletedLocal,
        'userExists': true,
        'hasLocalSession': hasLocalSession,
      };
    }
  }

  Future<void> _mergeLocalFlagsIntoFirestore(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool paidLocal = prefs.getBool('paid') ?? false;
      final bool profileCompletedLocal =
          prefs.getBool('profileCompleted') ?? false;
      final String? roleLocal = prefs.getString('role');

      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final Map<String, dynamic> update = {};

      if (paidLocal) update['paid'] = true;
      if (profileCompletedLocal) update['profileCompleted'] = true;
      if (roleLocal != null && roleLocal.isNotEmpty) {
        update['role'] = roleLocal;
      }

      if (update.isNotEmpty) {
        await docRef.set(update, SetOptions(merge: true));
        debugPrint(
            'Merged local flags into Firestore for uid=${user.uid}: $update');
      }
    } catch (e) {
      debugPrint('Error merging local flags into Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pan Property Advisor',
      debugShowCheckedModeBanner: false,
      routes: {
        '/loginPage': (_) => const LoginPage(),
        '/aboutYou': (_) => const AboutYouPage(),
        '/knowYourFinances': (_) => const KnowYourFinancePage(),
        '/comingSoon': (_) => const ComingSoonPage(),
        '/passcodeLogin': (_) => const PasscodeLoginPage(),

        // Investor Routes
        '/investorAboutYou': (_) => const InvestorAboutYouPage(),
        '/investorTerms': (_) => const InvestorTermsPage(),
        '/investorDashboard': (_) => const InvestorDashboard(),

        // Mortgage Broker Routes
        '/mortgageBrokerIntro': (_) => const MortgageBrokerIntroPage(),
        '/mortgageBrokerAboutYou': (_) => const MortgageBrokerAboutYouPage(),
        '/mortgageBrokerDashboard': (_) => const MortgageBrokerDashboard(),
        '/brokerDashboard': (_) => const MortgageBrokerDashboard(),

        // Buyer's Agent Routes
        '/buyersAgentIntro': (_) => const BuyersAgentIntroPage(),
        '/buyersAgentAboutYou': (_) => const BuyersAgentAboutYouPage(),
        '/buyersAgentDashboard': (_) => const BuyersAgentDashboard(),

        // Diagnostic / Debug Route
        '/debugState': (_) => Scaffold(
              appBar: AppBar(title: const Text('Debug State')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final prefs = await SharedPreferences.getInstance();
                    debugPrint('DEBUG USER: $user');
                    debugPrint('DEBUG USER UID: ${user?.uid}');
                    debugPrint('DEBUG PREFS paid: ${prefs.getBool('paid')}');
                    debugPrint(
                        'DEBUG PREFS profileCompleted: ${prefs.getBool('profileCompleted')}');
                    debugPrint(
                        'DEBUG PREFS role: ${prefs.getString('role')}');
                    debugPrint(
                        'DEBUG PREFS userPasscode: ${prefs.getString('userPasscode')}');
                    if (user != null) {
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();
                      debugPrint(
                          'DEBUG FIRESTORE doc exists: ${doc.exists}, data: ${doc.data()}');
                    }
                  },
                  child: const Text('Print auth + prefs + firestore'),
                ),
              ),
            ),
      },
      onGenerateRoute: (settings) {
        // ========== ADD THIS BLOCK ==========
// lib/main.dart
        if (settings.name == '/mortgageBrokerDetails') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => MortgageBrokerDetailsPage(
              initialData: args,
            ),
          );
        }

        if (settings.name == '/mortgageBrokerPreview') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => MortgageBrokerPreviewPage(
              fullName: args['fullName'] ?? '',
              title: args['title'] ?? '',
              companyName: args['companyName'] ?? '',
              experience: args['experience'] ?? '',
              creditLicence: args['creditLicence'] ?? '',
              afcaNumber: args['afcaNumber'] ?? '',
              aggregator: args['aggregator'] ?? '',
              shortBio: args['shortBio'] ?? '',
              fullBio: args['fullBio'] ?? '',
              difference: args['difference'] ?? '',
              awards: args['awards'] ?? '',
              testimonials: args['testimonials'] ?? '',
              email: args['email'] ?? '',
              mobile: args['mobile'] ?? '',
              officeAddress: args['officeAddress'] ?? '',
              serviceAreas: args['serviceAreas'] ?? '',
              linkedin: args['linkedin'] ?? '',
              googleReviews: args['googleReviews'] ?? '',
              website: args['website'] ?? '',
            ),
          );
        }
        
        if (settings.name == '/buyersAgentDetails') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => BuyersAgentDetailsPage(
              initialData: args,
            ),
          );
        }

        if (settings.name == '/paymentPage') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => PaymentPage(
              amountPaid: args['amountPaid']?.toString(),
              paymentDate: args['paymentDate']?.toString(),
              isPaid: args['isPaid'] == true || args['paid'] == true,
            ),
          );
        }

        if (settings.name == '/mortgageBrokerPreview') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => MortgageBrokerPreviewPage(
              fullName: args['fullName'] ?? '',
              title: args['title'] ?? '',
              companyName: args['companyName'] ?? '',
              experience: args['experience'] ?? '',
              creditLicence: args['creditLicence'] ?? '',
              afcaNumber: args['afcaNumber'] ?? '',
              aggregator: args['aggregator'] ?? '',
              shortBio: args['shortBio'] ?? '',
              fullBio: args['fullBio'] ?? '',
              difference: args['difference'] ?? '',
              awards: args['awards'] ?? '',
              testimonials: args['testimonials'] ?? '',
              email: args['email'] ?? '',
              mobile: args['mobile'] ?? '',
              officeAddress: args['officeAddress'] ?? '',
              serviceAreas: args['serviceAreas'] ?? '',
              linkedin: args['linkedin'] ?? '',
              googleReviews: args['googleReviews'] ?? '',
              website: args['website'] ?? '',
            ),
          );
        }

        if (settings.name == '/buyersAgentPreview') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => BuyersAgentPreviewPage(
              fullName: args['fullName'] ?? '',
              title: args['title'] ?? '',
              companyName: args['companyName'] ?? '',
              experience: args['experience'] ?? '',
              licenceNumber: args['licenceNumber'] ?? '',
              afcaNumber: args['afcaNumber'] ?? '',
              specialisation: args['specialisation'] ?? '',
              states: args['states'] ?? '',
              shortBio: args['shortBio'] ?? '',
              fullBio: args['fullBio'] ?? '',
              difference: args['difference'] ?? '',
              awards: args['awards'] ?? '',
              testimonials: args['testimonials'] ?? '',
              email: args['email'] ?? '',
              mobile: args['mobile'] ?? '',
              officeAddress: args['officeAddress'] ?? '',
              serviceAreas: args['serviceAreas'] ?? '',
              linkedin: args['linkedin'] ?? '',
              googleReviews: args['googleReviews'] ?? '',
              website: args['website'] ?? '',
            ),
          );
        }
        return null;
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = authSnapshot.data;

          if (user != null) {
            Future.microtask(() => _mergeLocalFlagsIntoFirestore(user));
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: _readState(user),
            builder: (context, stateSnap) {
              if (stateSnap.connectionState == ConnectionState.waiting ||
                  !stateSnap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final state = stateSnap.data!;
              final bool userExists = state['userExists'] as bool? ?? false;
              final bool hasLocalSession =
                  state['hasLocalSession'] as bool? ?? false;
              final String? role = state['role'] as String?;
              final bool paid = state['paid'] as bool? ?? false;
              final bool profileCompleted =
                  state['profileCompleted'] as bool? ?? false;

              // Scenario 1: Unauthenticated
              if (user == null || !userExists) {
                if (hasLocalSession) {
                  debugPrint('→ Routing returning user to LoginPage');
                  return const HomeLogoPage(next: LoginPage());
                }

                debugPrint('→ Routing new user to WelcomePage');
                return const HomeLogoPage(next: WelcomePage());
              }

              // Scenario 2: Unpaid User -> Route to Passcode entry then Payment
              if (!paid) {
                return const HomeLogoPage(next: PasscodeLoginPage());
              }

              // Scenario 3: Paid, but incomplete setup profile
              if (!profileCompleted) {
                if (role == 'mortgage_broker') {
                  return const HomeLogoPage(
                      next: MortgageBrokerAboutYouPage());
                } else if (role == 'buyers_agent') {
                  return const HomeLogoPage(
                      next: BuyersAgentAboutYouPage());
                } else {
                  return const HomeLogoPage(next: InvestorAboutYouPage());
                }
              }

              // Scenario 4: Fully onboarded user -> Direct to Dashboard
              if (role == 'mortgage_broker') {
                return const HomeLogoPage(next: MortgageBrokerDashboard());
              } else if (role == 'buyers_agent') {
                return const HomeLogoPage(next: BuyersAgentDashboard());
              } else {
                return const HomeLogoPage(next: InvestorDashboard());
              }
            },
          );
        },
      ),
    );
  }
}