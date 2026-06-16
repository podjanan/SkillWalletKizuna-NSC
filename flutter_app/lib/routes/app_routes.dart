// lib/routes/app_routes.dart

import 'package:flutter/material.dart';

// --- Auth & Core Screens ---
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/children_info_screen.dart';
import '../screens/auth/email_login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/all_activities_screen.dart';

// --- Activities & Hubs ---
import '../screens/activities/hub/language_hub_screen.dart';
import '../screens/activities/listing/language_list_screen.dart';
import '../screens/activities/gameplay/item_intro_screen.dart';
import '../screens/activities/gameplay/record_screen.dart';
import '../screens/activities/gameplay/result_screen.dart';
import '../models/activity.dart';
import '../screens/activities/detail/physical_video_screen.dart';
import '../screens/activities/detail/language_detail_screen.dart';
import '../screens/activities/detail/physical_detail_screen.dart';
import '../screens/activities/detail/calculate_activity_screen.dart';


// --- Child Management Screens ---
import '../screens/child/child_setting_screen.dart';
import '../screens/child/add_child_screen.dart';

class AppRoutes {
  // --- Core Routes ---
  static const String home = '/';
  static const String welcome = '/welcome';

  // --- Auth Routes ---
  static const String childrenInfo = '/children-info';
  static const String emailLogin = '/email-login';

  // --- Activity Routes ---
  static const String languageHub = '/language-hub';
  static const String languageList = '/language-list';
  static const String itemIntro = '/item-intro';
  static const String record = '/record';
  static const String result = '/result';
  static const String videoDetail = '/video-detail';
  static const String languageDetail = '/language-detail';
  static const String physicalActivity = '/physical-activity';
  static const String calculateActivity = '/calculate-activity';

  // --- All Activities Routes ---
  static const String allActivities = '/all-activities';

  // --- Child Management Routes ---
  static const String childSetting = '/child-setting';
  static const String addChild = '/add-child';

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        // Core
        welcome: (_) => const WelcomeScreen(),
        home: (_) => const HomeScreen(),

        // Auth
        childrenInfo: (_) => const ChildrenInfoScreen(),
        emailLogin: (_) => const EmailLoginScreen(),

        // Activities
        languageHub: (_) => const LanguageHubScreen(),
        languageList: (_) => const LanguageListScreen(),

        // Item Intro
        itemIntro: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args == null || args is! Activity) {
            return const Scaffold(
              body: Center(
                child: Text('No Activity data passed to ItemIntroScreen'),
              ),
            );
          }
          return ItemIntroScreen(activity: args);
        },

        record: (_) => const RecordScreen(),

        // Detail Screens
        videoDetail: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return PhysicalVideoScreen(activity: activity);
        },
        languageDetail: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return LanguageDetailScreen(activity: activity);
        },
        physicalActivity: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Activity) {
            return PhysicalDetailScreen(activity: args);
          }
          final map = args as Map<String, dynamic>;
          return PhysicalDetailScreen(
            activity: map['activity'] as Activity,
            extraChildIds:
                List<String>.from(map['extraChildIds'] as List? ?? []),
          );
        },
        calculateActivity: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return CalculateActivityScreen(activity: activity);
        },

        // --- All Activities ---
        allActivities: (context) {
          final type = ModalRoute.of(context)!.settings.arguments as ActivityListType;
          return AllActivitiesScreen(type: type);
        },

        // --- Child Management Section ---
        childSetting: (_) => const ChildSettingScreen(),
        addChild: (_) => const AddChildScreen(),

        // Result
        result: (_) => const ResultScreen(),
      };
}
