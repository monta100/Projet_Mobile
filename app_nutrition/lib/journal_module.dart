import 'package:app_nutrition/journal/ui/journal_home_page.dart';
import 'package:app_nutrition/journal/ai_doctor/ai_doctor_page.dart';
import 'package:app_nutrition/modules/dashboard/dashboard_page.dart';
import 'package:app_nutrition/modules/profile/profile_page.dart';
import 'package:app_nutrition/modules/wellbeing/wellbeing_page.dart';
import 'package:flutter/material.dart';

class JournalModule {
  static Map<String, WidgetBuilder> routes() => {
    '/journal': (_) => const DashboardPage(),
    '/journal/home': (_) => const JournalHomePage(),
    '/profile': (_) => const ProfilePage(),
    '/wellbeing': (_) => const WellbeingPage(),
    '/ai-doctor': (_) => const AiDoctorPage(),
  };
}
