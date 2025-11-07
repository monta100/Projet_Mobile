import 'package:app_nutrition/journal/ai_doctor/ai_doctor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'common/app_theme.dart';
import 'journal/ui/journal_home_page.dart';
import 'modules/water/water_notifs.dart';
import 'modules/dashboard/dashboard_page.dart';
import 'modules/profile/profile_page.dart';
import 'modules/wellbeing/wellbeing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WaterNotifs.init(); // init notifications & timezone
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition & Coaching',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routes: {
        '/journal': (_) => const JournalHomePage(),
        '/dashboard': (_) => const DashboardPage(),
        '/profile': (_) => const ProfilePage(),
        '/wellbeing': (_) => const WellbeingPage(),
          '/ai-doctor': (_) => const AiDoctorPage(), // 👈

      },
      home: const DashboardPage(),
    );
  }
}
