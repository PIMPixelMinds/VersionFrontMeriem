import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/locale_provider.dart';
import 'core/utils/medication_notification_helper.dart';

import 'view/auth/firebase_auth_api.dart';
import 'view/body/firebase_historique_api.dart';
import 'view/appointment/firebase_api.dart';

import 'view/home/splash_screen.dart';
import 'view/home/check_login_page.dart';
import 'view/home/home_page.dart';

import 'view/auth/login_page.dart';
import 'view/auth/register_page.dart';
import 'view/auth/password_security_page.dart';
import 'view/auth/perso_information_page.dart';
import 'view/auth/medical_history_page.dart';
import 'view/auth/primary_caregiver_page.dart';
import 'view/auth/profile_page.dart';

import 'view/appointment/add_appointment.dart';
import 'view/appointment/appointment_view.dart';
import 'view/appointment/notification_page.dart';

import 'view/medication/add_medication_screen.dart';
import 'view/medication/medication_home_screen.dart';
import 'view/medication/medication_detail_screen.dart';
import 'view/medication/medication_notification_screen.dart';

import 'view/tracking_log/health_page.dart';

import 'viewmodel/auth_viewmodel.dart';
import 'viewmodel/appointment_viewmodel.dart';
import 'viewmodel/healthTracker_viewmodel.dart';
import 'viewmodel/medication_viewmodel.dart';


/// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Local notifications plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Firebase background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  await _setupNotifications();

  runApp(const MyApp());
}

Future<void> _setupNotifications() async {
  await MedicationNotificationHelper.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'health_channel',
    'Health Notifications',
    description: 'Notifications for health predictions',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      debugPrint('🔔 Notification tapped: ${response.payload}');
    },
  );

  final iosImpl =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
  final granted = await iosImpl?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('🔐 iOS notification permission granted: $granted');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 Foreground message: ${message.notification?.title}");
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  });
}

///
/// 🧩 Modified MyApp to support mock injection for tests
///
class MyApp extends StatelessWidget {
  final FirebaseApi? firebaseApi;
  final FirebaseHistoriqueApi? firebaseHistoriqueApi;
  final FirebaseAuthApi? firebaseAuthApi;

  const MyApp({
    super.key,
    this.firebaseApi,
    this.firebaseHistoriqueApi,
    this.firebaseAuthApi,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize Firebase-related APIs
    (firebaseApi ?? FirebaseApi()).initNotifications('temp-id');
    (firebaseHistoriqueApi ?? FirebaseHistoriqueApi())
        .initNotifications('temp-id');
    (firebaseAuthApi ?? FirebaseAuthApi()).initNotifications('temp-id');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AppointmentViewModel()),
        ChangeNotifierProvider(create: (_) => MedicationViewModel()),
        ChangeNotifierProvider(create: (_) => HealthTrackerViewModel()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: ThemeMode.system,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en'), Locale('fr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primaryBlue,
            fontFamily: 'Montserrat',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.primaryBlue,
            fontFamily: 'Montserrat',
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/checkLogin': (context) => const CheckLoginPage(),
            '/login': (context) => LoginPage(),
            '/register': (context) => RegisterPage(),
            '/home': (context) => const HomePage(),
            '/passwordSecurity': (context) => const PasswordSecurityPage(),
            '/personalInformation': (context) =>
                const PersonalInformationPage(),
            '/medicalHistory': (context) => const MedicalHistoryPage(),
            '/primaryCaregiver': (context) => const PrimaryCaregiverPage(),
            '/addAppointment': (context) => const AddAppointmentSheet(),
            '/displayAppointment': (context) => const AppointmentPage(),
            '/notification_screen': (context) => const NotificationPage(),
            '/medications': (context) => const MedicationHomeScreen(),
            '/add_medication': (context) => AddMedicationScreen(),
            '/medication_notifications': (context) =>
                const MedicationNotificationScreen(),
            '/medication_detail': (context) => MedicationDetailScreen(
                  medicationId:
                      ModalRoute.of(context)!.settings.arguments as String,
                ),
            '/profile': (context) => const ProfilePage(),
            '/healthPage': (context) => HealthPage(),
          },
        ),
      ),
    );
  }
}
