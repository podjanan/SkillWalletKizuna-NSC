import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';

import '../theme/palette.dart';
import '../theme/app_text_styles.dart';

/// Data model for share content
class ShareResultData {
  final String activityName;
  final int score;
  final int maxScore;
  final int timeSpentSeconds;
  final String? category;
  final String? evidenceImagePath;

  const ShareResultData({
    required this.activityName,
    required this.score,
    required this.maxScore,
    required this.timeSpentSeconds,
    this.category,
    this.evidenceImagePath,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
  bool get isPassed => percentage >= 70;

  /// Check if evidence image exists on disk
  bool get hasEvidenceImage =>
      !kIsWeb &&
      evidenceImagePath != null &&
      evidenceImagePath!.isNotEmpty &&
      File(evidenceImagePath!).existsSync();
}

/// Shows share bottom sheet with options
Future<void> showShareBottomSheet(
  BuildContext context,
  ShareResultData data,
) async {
  final l = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ShareBottomSheet(data: data, l: l),
  );
}

class _ShareBottomSheet extends StatefulWidget {
  final ShareResultData data;
  final AppLocalizations l;

  const _ShareBottomSheet({required this.data, required this.l});

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Rect _getSharePositionOrigin() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      if (size.width > 0 && size.height > 0) {
        return renderBox.localToGlobal(Offset.zero) & size;
      }
    }

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox != null && overlayBox.hasSize) {
      final size = overlayBox.size;
      return Rect.fromCenter(
        center: size.center(Offset.zero),
        width: 1,
        height: 1,
      );
    }

    return const Rect.fromLTWH(0, 0, 1, 1);
  }

  String _formatTime(int seconds) {
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _buildShareText() {
    final d = widget.data;
    final l = widget.l;
    final emoji = d.isPassed ? '🎉' : '💪';
    return '$emoji ${l.share_textTemplate(d.activityName, d.score, d.maxScore)}';
  }

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final d = widget.data;
      final origin = _getSharePositionOrigin();
      final text = _buildShareText();

      if (d.hasEvidenceImage) {
        if (!mounted) return;
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(d.evidenceImagePath!)],
          text: text,
          sharePositionOrigin: origin,
        );
      } else {
        final boundary = _cardKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) return;

        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return;

        final Uint8List pngBytes = byteData.buffer.asUint8List();

        if (!mounted) return;
        Navigator.pop(context);

        await Share.shareXFiles(
          [XFile.fromData(pngBytes, mimeType: 'image/png', name: 'result.png')],
          text: text,
          sharePositionOrigin: origin,
        );
      }
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _copyShareText() async {
    await Clipboard.setData(ClipboardData(text: _buildShareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied share text')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final d = widget.data;
    final pct = d.maxScore > 0 ? (d.score / d.maxScore).clamp(0.0, 1.0) : 0.0;
    final scoreColor = pct <= 0.5
        ? Color.lerp(const Color(0xFFE53935), const Color(0xFFFDD835), pct * 2)!
        : Color.lerp(const Color(0xFFFDD835), const Color(0xFF43A047), (pct - 0.5) * 2)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Palette.labelGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(l.share_title, style: AppTextStyles.heading(20)),
            const SizedBox(height: 16),

            // Preview card
            if (d.hasEvidenceImage)
              // Show actual evidence image with score overlay
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      File(d.evidenceImagePath!),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                    // Dark gradient overlay at bottom for readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.activityName,
                                style:
                                    AppTextStyles.label(13, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: scoreColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${d.score}/${d.maxScore}',
                                style:
                                    AppTextStyles.label(13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Fallback: score card (captured as screenshot)
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Palette.cream,
                        scoreColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('Skill Wallet Kizuna',
                          style: AppTextStyles.heading(14, color: Palette.sky)),
                      const SizedBox(height: 12),
                      Text(
                        d.activityName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading(16, color: Palette.deepGrey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${d.score} / ${d.maxScore}',
                        style: AppTextStyles.heading(40, color: scoreColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.isPassed ? l.share_greatJob : l.share_keepTrying,
                        style: AppTextStyles.heading(16, color: scoreColor),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16, color: Palette.deepGrey),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(d.timeSpentSeconds),
                            style:
                                AppTextStyles.body(13, color: Palette.deepGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Share button
            _ShareOptionButton(
              icon: kIsWeb ? Icons.download_rounded : Icons.share_rounded,
              label: kIsWeb ? 'Share / Download image' : l.share_title,
              color: Palette.sky,
              onTap: _share,
              isLoading: _isSharing,
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 10),
              _ShareOptionButton(
                icon: Icons.copy_rounded,
                label: 'Copy share text',
                color: Palette.successAlt,
                onTap: _copyShareText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ShareOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.label(12, color: color)),
          ],
        ),
      ),
    );
  }
}
