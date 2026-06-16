// lib/screens/language_list_screen.dart

import 'package:flutter/material.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/ui.dart';
import '../../../models/language_flow.dart';
import '../../../models/activity.dart';
import '../../../services/activity_service.dart';
import '../../../routes/app_routes.dart';

class LanguageListScreen extends StatefulWidget {
  const LanguageListScreen({super.key});

  @override
  State<LanguageListScreen> createState() => _LanguageListScreenState();
}

class _LanguageListScreenState extends State<LanguageListScreen> {
  final ActivityService _activityService = ActivityService();
  List<Activity> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final args = ModalRoute.of(context)!.settings.arguments as LangListArgs;

    // แปลง level จาก EASY/MEDIUM/DIFFICULT → ง่าย/กลาง/ยาก
    String level;
    switch (args.level.toUpperCase()) {
      case 'EASY':
        level = 'ง่าย';
        break;
      case 'MEDIUM':
        level = 'กลาง';
        break;
      case 'DIFFICULT':
        level = 'ยาก';
        break;
      default:
        level = 'ง่าย';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activities = await _activityService.fetchLanguageActivities(
        topic: args.topic,
        level: level,
      );

      setState(() {
        _activities = activities;
        _isLoading = false;
      });

      // Debug: แสดงข้อมูลที่ได้
      debugPrint(
          '📚 Loaded ${activities.length} activities for ${args.topic} ($level)');
      if (activities.isNotEmpty) {
        debugPrint('📋 First activity: ${activities.first.name}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่สามารถโหลดข้อมูลได้: $e';
      });
      debugPrint('❌ Error loading activities: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as LangListArgs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: Text(args.topic, style: luckiestH(18, color: Palette.sky)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: AppTextStyles.body(16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadActivities,
                child: Text(AppLocalizations.of(context)!.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'ยังไม่มีกิจกรรมในหมวดนี้',
                style: AppTextStyles.body(16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final activity = _activities[i];
        return OutlineCard(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.languageDetail,
              arguments: activity,
            );
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name.toUpperCase(),
                      style: AppTextStyles.heading(16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activity.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        activity.description!,
                        style: AppTextStyles.body(12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(activity.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity.difficulty,
                      style: AppTextStyles.body(10,
                          color: Colors.white, weight: FontWeight.bold),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: Palette.sky,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'ง่าย':
        return Palette.successAlt;
      case 'กลาง':
        return Palette.yellow;
      case 'ยาก':
        return Palette.pink;
      default:
        return Colors.grey;
    }
  }
}
