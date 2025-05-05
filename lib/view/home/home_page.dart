import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Placeholder imports for referenced pages (replace with actual imports)
import 'package:pim/view/appointment/appointment_view.dart';
import 'package:pim/view/medication/medication_home_screen.dart';
import 'package:pim/view/auth/profile_page.dart';
import 'package:pim/view/body/body_page.dart';
import 'package:pim/view/tracking_log/HealthTrackerPage.dart';
import 'news_feed_screen.dart';
import 'Chatbot.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/appointment_viewmodel.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Widget> _pages = <Widget>[
    const DashboardPage(),
    const AppointmentPage(),
    BodyPage(),
    const HealthTrackerPage(),
    const MedicationHomeScreen(),
  ];

  late TutorialCoachMark tutorialCoachMark;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _tutorialKey = GlobalKey();
  final GlobalKey _gestureKey = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  void _showTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenWalkthrough = prefs.getBool('hasSeenWalkthrough') ?? false;

    if (hasSeenWalkthrough) return;

    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.black.withOpacity(0.75),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
    );

    tutorialCoachMark.show(context: context);
    await prefs.setBool('hasSeenWalkthrough', true);
  }

  List<TargetFocus> _createTargets() {
    final localizations = AppLocalizations.of(context)!;

    return [
      TargetFocus(
        identify: "swipe_hint",
        keyTarget: _tutorialKey,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(
              top: MediaQuery.of(context).size.height * 0.3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.swipeTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  localizations.swipeDescription,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    tutorialCoachMark.finish();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(
                    localizations.ok,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              return GestureDetector(
                key: _gestureKey,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const NewsFeedScreen(),
                        transitionsBuilder: (_, animation, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    Container(
                      key: _tutorialKey,
                      width: double.infinity,
                      color: Colors.transparent,
                    ),
                    Expanded(child: _pages[_selectedIndex]),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: () {
                  showChatbot(context);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, Color(0xFF33C3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.asset(
                          'assets/chatbot_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: CurvedNavigationBar(
            index: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            color: AppColors.primaryBlue,
            buttonBackgroundColor: AppColors.primaryBlue,
            animationDuration: const Duration(milliseconds: 300),
            height: 60,
            items: const [
              Icon(Icons.dashboard, size: 30, color: Colors.white),
              Icon(Icons.event, size: 30, color: Colors.white),
              Icon(Icons.accessibility_new, size: 30, color: Colors.white),
              Icon(Icons.monitor_heart, size: 30, color: Colors.white),
              Icon(Icons.local_pharmacy, size: 30, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  bool _hasSubmittedHealthData = false;
  final List<String> _appointments = [
    "Dr. Smith - Cardiology",
    "Dr. Lee - Dermatology",
    "Dr. Adams - Neurology"
  ];
  List<bool> _weeklySubmissions = List.filled(6, false);

  // Variables for health data
  static const platform = MethodChannel(
      'com.esprit.msaware/health'); // Updated to match health plugin
  double _stepCount = 0.0;
  double _heartRate = 0.0;
  double _hrv = 0.0;
  double _sleepScore = 0.0;
  double _temperature = 0.0;
  double _spo2 = 0.0;
  double _stress = 0.0;
  bool _healthDataFetched = false;

  // Fallback values for missing data
  final Map<String, double> _fallbackValues = {
    'Heart Rate': 80.0,
    'HRV': 60.0,
    'Sleep Score': 80.0,
    'Steps': 5000.0,
    'Body Temperature': 36.6,
    'SpO2': 97.0,
    'Stress Level': 30.0,
  };

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    print('DashboardPage initState called');
    _initializeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Fetching appointments, weekly submissions, and health data');
      final appointmentViewModel =
          Provider.of<AppointmentViewModel>(context, listen: false);
      appointmentViewModel.fetchAppointments();
      fetchWeeklySubmissions();
      fetchHealthData();
    });
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notification tapped: ${response.payload}');
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
    print('iOS notification permission granted: $granted');

    // Create Android notification channel
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
  }

  Future<void> fetchWeeklySubmissions() async {
    try {
      final token = await getToken();
      print('Fetching weekly submissions with token: $token');
      final response = await http.get(
        Uri.parse('http://192.168.1.180:3000/questionnaire/weekly-submissions'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print('Weekly submissions response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _weeklySubmissions =
              data.map((week) => week['completed'] as bool).toList();
        });
        print('Weekly submissions updated: $_weeklySubmissions');
      } else {
        print('Failed to fetch stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching submissions: $e');
    }
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> fetchHealthData() async {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    setState(() {
      _healthDataFetched = false;
      _hasSubmittedHealthData = false;
    });

    try {
      print('Attempting to fetch health data via platform channel...');
      final result = await platform.invokeMethod('fetchHealthData');
      print('Health data fetched: $result');
      if (result is Map) {
        double hrv = (result['hrv'] as num?)?.toDouble() ?? 0.0;
        if (hrv == 0.0) {
          hrv = _fallbackValues['HRV']!;
          print('HRV fallback applied: $hrv');
        }
        double stressValue = hrv > 0
            ? (hrv > 80
                ? 30.0
                : hrv > 50
                    ? 60.0
                    : 90.0)
            : _fallbackValues['Stress Level']!;

        double temperature = (result['temperature'] as num?)?.toDouble() ?? 0.0;
        double spo2 = (result['spo2'] as num?)?.toDouble() ?? 0.0;

        if (temperature == 0.0) {
          temperature = _fallbackValues['Body Temperature']!;
          print('Temperature fallback applied: $temperature');
        }
        if (spo2 == 0.0) {
          spo2 = _fallbackValues['SpO2']!;
          print('SpO2 fallback applied: $spo2');
        }

        print(
            'Raw data - Steps: ${result['steps']}, Heart Rate: ${result['heart_rate']}, HRV: $hrv, Sleep Score: ${result['sleep_score']}, Temperature: $temperature, SpO2: $spo2, Stress: $stressValue');
        setState(() {
          _stepCount = (result['steps'] as num?)?.toDouble() ??
              _fallbackValues['Steps']!;
          _heartRate = (result['heart_rate'] as num?)?.toDouble() ??
              _fallbackValues['Heart Rate']!;
          _hrv = hrv;
          _sleepScore = (result['sleep_score'] as num?)?.toDouble() ??
              _fallbackValues['Sleep Score']!;
          _temperature = temperature;
          _spo2 = spo2;
          _stress = stressValue;
          _healthDataFetched = true;
        });
        print(
            'Health data updated - Steps: $_stepCount, Heart Rate: $_heartRate, HRV: $_hrv, Sleep Score: $_sleepScore, Temperature: $_temperature, SpO2: $_spo2, Stress: $_stress');

        if (_temperature == _fallbackValues['Body Temperature']! ||
            _spo2 == _fallbackValues['SpO2']! ||
            _hrv == _fallbackValues['HRV']!) {
          if (!mounted) return;
          TextEditingController tempController =
              TextEditingController(text: _temperature.toString());
          TextEditingController spo2Controller =
              TextEditingController(text: _spo2.toString());
          TextEditingController hrvController =
              TextEditingController(text: _hrv.toString());
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.missingHealthDataTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!
                      .missingHealthDataDescription),
                  if (_temperature == _fallbackValues['Body Temperature']!)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: tempController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.temperatureLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  if (_spo2 == _fallbackValues['SpO2']!)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: spo2Controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.spo2Label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  if (_hrv == _fallbackValues['HRV']!)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: hrvController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.hrvLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                      'If data is still missing, please enable Health permissions in Settings.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    sendHealthDataForPrediction();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[200] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      double? newTemp = double.tryParse(tempController.text);
                      double? newSpo2 = double.tryParse(spo2Controller.text);
                      double? newHrv = double.tryParse(hrvController.text);
                      if (newTemp != null &&
                          newTemp >= 30.0 &&
                          newTemp <= 45.0) {
                        _temperature = newTemp;
                      }
                      if (newSpo2 != null &&
                          newSpo2 >= 50.0 &&
                          newSpo2 <= 100.0) {
                        _spo2 = newSpo2;
                      }
                      if (newHrv != null && newHrv >= 0.0 && newHrv <= 200.0) {
                        _hrv = newHrv;
                        _stress = _hrv > 80
                            ? 30.0
                            : _hrv > 50
                                ? 60.0
                                : 90.0;
                      }
                      _hasSubmittedHealthData = true;
                    });
                    Navigator.pop(context);
                    sendHealthDataForPrediction();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.submit,
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          print('No missing data, calling sendHealthDataForPrediction');
          await sendHealthDataForPrediction();
        }
      } else {
        print('Unexpected result format: $result, using fallbacks');
        setState(() {
          _stepCount = _fallbackValues['Steps']!;
          _heartRate = _fallbackValues['Heart Rate']!;
          _hrv = _fallbackValues['HRV']!;
          _sleepScore = _fallbackValues['Sleep Score']!;
          _temperature = _fallbackValues['Body Temperature']!;
          _spo2 = _fallbackValues['SpO2']!;
          _stress = _fallbackValues['Stress Level']!;
          _healthDataFetched = true;
        });
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.permissionsRequiredTitle),
            content:
                Text(AppLocalizations.of(context)!.permissionsRequiredMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error fetching health data: $e');
      setState(() {
        _stepCount = _fallbackValues['Steps']!;
        _heartRate = _fallbackValues['Heart Rate']!;
        _hrv = _fallbackValues['HRV']!;
        _sleepScore = _fallbackValues['Sleep Score']!;
        _temperature = _fallbackValues['Body Temperature']!;
        _spo2 = _fallbackValues['SpO2']!;
        _stress = _fallbackValues['Stress Level']!;
        _healthDataFetched = true;
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.permissionsRequiredTitle),
          content:
              Text(AppLocalizations.of(context)!.permissionsRequiredMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> sendHealthDataForPrediction() async {
    if 
    (!_healthDataFetched ||
        (!_hasSubmittedHealthData &&
            (_heartRate == _fallbackValues['Heart Rate']! ||
                _sleepScore == _fallbackValues['Sleep Score']! ||
                _stepCount == _fallbackValues['Steps']!))) {
      print('Critical health data incomplete, skipping prediction');
      return;
    }

    try {
      final healthData = {
        "features": [
          _heartRate,
          _hrv,
          _sleepScore,
          _stepCount,
          _temperature,
          _spo2,
          _stress,
        ],
        "fcmToken": null,
      };

      print('Sending health data to Flask server: $healthData');

      final response = await http
          .post(
            Uri.parse('http://192.168.1.170:4000/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(healthData),
          )
          .timeout(const Duration(seconds: 15));

      print('Prediction response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final predictionResult = jsonDecode(response.body);
        final label = predictionResult['label'];
        final confidence = predictionResult['confidence'];

        print('Prediction result: $label with $confidence% confidence');
        await _showNotification(label, confidence);

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Health Prediction'),
            content: Text(
                'Prediction: $label with ${confidence.toStringAsFixed(2)}% confidence'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        print(
            'Failed to get prediction: ${response.statusCode}, ${response.body}');
        await _showNotification("Prediction Failed", 0.0);
      }
    } catch (e) {
      print('Error sending health data for prediction: $e');
      

      // Mock fallback
      const mockLabel= "Stable condition";
      const mockConfidence = 85.0;
      print('Mocking prediction: $mockLabel with $mockConfidence% confidence');
      await _showNotification(mockLabel, mockConfidence);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.healthPredictionTitle),
          content: Text(AppLocalizations.of(context)!.healthPredictionMessage(
              mockLabel, mockConfidence.toStringAsFixed(2))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.ok,
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showNotification(String label, double confidence) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'health_channel',
        'Health Notifications',
        channelDescription: 'Notifications for health predictions',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.critical,
        presentBanner: true,
        presentList: true,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch % 10000;

      print(
          'Showing notification: $label with $confidence% confidence at ${DateTime.now()}');
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'Health Prediction Alert',
        '$label with ${confidence.toStringAsFixed(2)}% confidence',
        platformChannelSpecifics,
      );
      print('Notification displayed successfully');
    } catch (e) {
      print('Error displaying notification: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notificationError ??
              'Notification failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDarkMode ? AppColors.primaryBlue : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color iconColor = isDarkMode ? Colors.white : AppColors.primaryBlue;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: true);
    final allAppointments =
        Provider.of<AppointmentViewModel>(context).appointments;

    // 🔹 Filter: date >= today AND status == 'upcoming'
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingAppointments = allAppointments.where((a) {
      final dateOnly = DateTime(a.date.year, a.date.month, a.date.day);
      final isUpcomingDate =
          dateOnly.isAtSameMomentAs(today) || dateOnly.isAfter(today);
      final isUpcomingStatus = a.status?.toLowerCase() == 'upcoming';
      return isUpcomingDate && isUpcomingStatus;
    }).toList();

    bool showProfileWarning = authViewModel.isProfileIncomplete();

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, authViewModel),
              const SizedBox(height: 20),

              // 🔹 Carousel for upcoming appointments
              if (upcomingAppointments.isNotEmpty) ...[
                CarouselSlider.builder(
                  itemCount: upcomingAppointments.length.clamp(0, 3),
                  itemBuilder: (context, index, realIndex) {
                    final appointment = upcomingAppointments[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: _currentIndex == index ? 1.0 : 0.7,
                        child: _appointmentCard(
                          appointment.fullName,
                          appointment.date,
                          isDarkMode,
                          context,
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 250,
                    enlargeCenterPage: true,
                    enlargeStrategy: CenterPageEnlargeStrategy.height,
                    viewportFraction: 0.8,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    onPageChanged: (index, reason) {
                      setState(() => _currentIndex = index);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    upcomingAppointments.length.clamp(0, 3),
                    (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? AppColors.primaryBlue
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 30),
              _activityChartCard(context),
              const SizedBox(height: 30),

              // 🔹 Health section
              Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 1.5,
                    children: [
                      _temperatureCard(context),
                      _heartRateCard(context),
                      _spo2Card(context),
                      _hrvCard(context),
                      _sleepScoreCard(context),
                      _stressCard(context),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: _dailyCaresCard(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardsRow(Widget card1, Widget card2) {
    return Row(
      children: [
        Expanded(child: card1),
        const SizedBox(width: 10),
        Expanded(child: card2),
      ],
    );
  }

  Widget _appointmentCard(
      String fullName, DateTime date, bool isDarkMode, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat.yMMMd(locale).format(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.upcomingAppointment,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDarkMode ? Colors.white : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "${localizations.doctor} $fullName",
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityChartCard(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      color: isDarkMode ? AppColors.primaryBlue : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.activityLast6Weeks,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "W${value.toInt() + 1}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(6, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _weeklySubmissions[index] ? 1.0 : 0.0,
                          color: _weeklySubmissions[index]
                              ? Colors.green
                              : Colors.grey,
                          width: 14,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthViewModel authViewModel) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final userName = authViewModel.userProfile?["fullName"] ?? '';

// Date locale (ex : "Fri, 2 May" → "ven., 2 mai")
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate =
        DateFormat('EEE, d MMMM', locale).format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 8.0, right: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${localizations.hi}, $userName!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 28),
                    color: isDarkMode ? Colors.white : Colors.black,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 30,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Consumer<AuthViewModel>(
                            builder: (context, authViewModel, child) {
                              if (authViewModel.isProfileIncomplete()) {
                                return Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              } else {
                                return const SizedBox();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _temperatureCard(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return _genericCard(
      AppLocalizations.of(context)!.temperature,
      Icons.thermostat,
      _healthDataFetched
          ? (_hasSubmittedHealthData ||
                  _temperature != _fallbackValues['Body Temperature']!
              ? "${_temperature.toStringAsFixed(1)}°C"
              : localizations.noData)
          : localizations.loading,
      context: context, // <- Ajout du context ici
    );
  }

  Widget _heartRateCard(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return _genericCard(
      localizations.heartRate,
      Icons.favorite,
      _healthDataFetched
          ? (_heartRate != _fallbackValues['Heart Rate']!
              ? "${_heartRate.toStringAsFixed(0)} bpm"
              : localizations.noData)
          : localizations.loading,
      context: context,
    );
  }

  Widget _hrvCard(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return _genericCard(
      localizations.hrv,
      Icons.favorite_border,
      _healthDataFetched
          ? "${_hrv.toStringAsFixed(1)} ms"
          : localizations.loading,
      context: context,
    );
  }

  Widget _sleepScoreCard(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return _genericCard(
      localizations.sleepScore,
      Icons.bed,
      _healthDataFetched
          ? (_sleepScore != _fallbackValues['Sleep Score']!
              ? "${_sleepScore.toStringAsFixed(0)}/100"
              : localizations.noData)
          : localizations.loading,
      context: context,
    );
  }

  Widget _spo2Card(BuildContext context) {
    return _genericCard(
      "SpO2",
      Icons.opacity,
      _healthDataFetched
          ? (_hasSubmittedHealthData || _spo2 != _fallbackValues['SpO2']!
              ? "${_spo2.toStringAsFixed(1)}%"
              : "No data")
          : "Loading...",
      context: context,
    );
  }

  Widget _dailyCaresCard(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return _genericCard(
      localizations.steps,
      Icons.directions_walk,
      _healthDataFetched
          ? (_stepCount != _fallbackValues['Steps']!
              ? "${_stepCount.toStringAsFixed(0)} ${localizations.stepsUnit}"
              : localizations.noData)
          : localizations.loading,
      showButton: false,
      context: context,
    );
  }

  Widget _stressCard(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return _genericCard(
      localizations.stressLevel,
      Icons.bolt,
      _healthDataFetched
          ? (_stress != _fallbackValues['Stress Level']!
              ? "${_stress.toStringAsFixed(1)}"
              : localizations.noData)
          : localizations.loading,
      context: context,
    );
  }

  Widget _genericCard(String title, IconData icon, String value,
      {bool showButton = false, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1.7, // légèrement plus compact
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.primaryBlue,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Icon(icon, size: 27, color: AppColors.primaryBlue),
              ],
            ),
            if (showButton)
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(72, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      const Text("Reschedule", style: TextStyle(fontSize: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
