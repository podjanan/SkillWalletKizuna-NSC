import 'package:flutter/material.dart';
import '../models/activity.dart';

typedef ActivityItemBuilder = Widget Function(Activity activity);

class ScrollableActivityList extends StatelessWidget {
  const ScrollableActivityList({
    super.key,
    required this.future,
    required this.controller,
    required this.emptyMessage,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.itemBuilder,
    this.emptyAction,
  });

  final Future<List<Activity>> future;
  final ScrollController controller;
  final String emptyMessage;
  final void Function(double dx) onDragStart;
  final void Function(double dx) onDragUpdate;
  final ActivityItemBuilder itemBuilder;
  /// Optional CTA widget shown below the empty message (e.g. a "View All" button).
  final Widget? emptyAction;

  static const sky = Color(0xFF0D92F4);
  static const deepSky = Color(0xFF7DBEF1);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Activity>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 155,
            child: Center(
              child: CircularProgressIndicator(color: sky),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 155,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: deepSky, width: 2),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emptyMessage,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (emptyAction != null) ...[
                  const SizedBox(height: 10),
                  emptyAction!,
                ],
              ],
            ),
          );
        }

        final activities = snapshot.data!;
        return GestureDetector(
          onHorizontalDragStart: (d) => onDragStart(d.globalPosition.dx),
          onHorizontalDragUpdate: (d) => onDragUpdate(d.globalPosition.dx),
          child: SizedBox(
            height: 155,
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  ...activities.map(itemBuilder),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
