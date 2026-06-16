// lib/screens/activities/detail/physical_video_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/activity.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/activity_l10n.dart';
import '../../../widgets/info_badges.dart';

class PhysicalVideoScreen extends StatefulWidget {
  static const String routeName = '/video_detail';

  final Activity activity;

  const PhysicalVideoScreen({
    super.key,
    required this.activity,
  });

  @override
  State<PhysicalVideoScreen> createState() => _PhysicalVideoScreenState();
}

class _PhysicalVideoScreenState extends State<PhysicalVideoScreen> {
  bool _howToPlayExpanded = false;
  List<String> _extraChildIds = [];
  InAppWebViewController? _webController;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.activity.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _fetchTikTokThumbnail(videoUrl);
    }
  }

  @override
  void dispose() {
    // pauseAllMediaPlayback is iOS-only
    if (Platform.isIOS) _webController?.pauseAllMediaPlayback();
    super.dispose();
  }

  Future<void> _fetchTikTokThumbnail(String videoUrl) async {
    try {
      final uri = Uri.parse(
        'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(videoUrl)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final thumb = data['thumbnail_url'] as String?;
        if (thumb != null) {
          // Inject thumbnail into the already-loaded InAppWebView
          _webController?.evaluateJavascript(source: '''
            (function() {
              var cover = document.getElementById('cover-overlay');
              if (!cover) return;
              var img = new Image();
              img.onload = function() {
                cover.style.backgroundImage = 'url("$thumb")';
                cover.dataset.ready = '1';
              };
              img.src = '$thumb';
            })();
          ''');
        }
      }
    } catch (_) {}
  }

  void _showChildPicker() {
    final userProvider = context.read<UserProvider>();
    final children = userProvider.children;
    final currentChildId = userProvider.currentChildId;
    final l = AppLocalizations.of(context)!;

    // Temp selection for the bottom sheet
    final tempSelected = Set<String>.from(_extraChildIds);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Palette.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.physical_addChildren,
                      style: AppTextStyles.heading(20, color: Palette.sky)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(l.physical_addChildrenDesc,
                  style: AppTextStyles.body(14, color: Colors.black54)),
              const SizedBox(height: 16),

              // Child list
              ...children.map((childData) {
                final info = childData['child'] as Map<String, dynamic>?;
                if (info == null) return const SizedBox.shrink();
                final childId = info['child_id'] as String;
                final childName = info['name_surname'] as String? ?? '';
                final isCurrent = childId == currentChildId;
                final isSelected = isCurrent || tempSelected.contains(childId);

                return GestureDetector(
                  onTap: isCurrent
                      ? null
                      : () {
                          setModalState(() {
                            if (tempSelected.contains(childId)) {
                              tempSelected.remove(childId);
                            } else {
                              tempSelected.add(childId);
                            }
                          });
                        },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Palette.sky.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Palette.sky : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Palette.sky : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Palette.sky.withValues(alpha: 0.2),
                          child: Text(
                            childName.isNotEmpty
                                ? childName[0].toUpperCase()
                                : '?',
                            style:
                                AppTextStyles.heading(16, color: Palette.sky),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(childName,
                              style: AppTextStyles.label(16,
                                  color: Colors.black87)),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Palette.sky,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(l.physical_currentChild,
                                style: AppTextStyles.label(11,
                                    color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _extraChildIds = tempSelected.toList();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.sky,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l.physical_confirm,
                      style: AppTextStyles.heading(18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final String videoUrl = activity.videoUrl ?? '';
    final String htmlContent = () {
      final stored = activity.tiktokHtmlContent ?? '';
      if (stored.isNotEmpty) return stored;
      // Fallback: build embed from videoUrl if tiktokHtmlContent not stored
      final videoId = _extractTikTokVideoId(videoUrl);
      if (videoId != null) return _buildTikTokBlockquote(videoId);
      return '';
    }();
    final String name = activity.name;
    final String content = activity.content;

    debugPrint('🎬 Physical Video Screen - ${activity.name}');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
            ActivityL10n.localizedActivityType(context, activity.category),
            style: AppTextStyles.heading(22, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Open in TikTok (TV) button
                  if (videoUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () async {
                          final appUri = Uri.parse(videoUrl);
                          if (await canLaunchUrl(appUri)) {
                            await launchUrl(appUri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.black.withValues(alpha: 0.2),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.tv_rounded,
                                  color: Colors.black54, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context)!
                                    .videodetail_openInTiktokTV,
                                style: AppTextStyles.label(13,
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  AspectRatio(
                    aspectRatio: 9 / 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: Colors.black,
                        child: htmlContent.isNotEmpty
                            ? InAppWebView(
                                onWebViewCreated: (c) => _webController = c,
                                initialData: InAppWebViewInitialData(
                                  data: buildResponsiveTikTokHtml(htmlContent),
                                  mimeType: 'text/html',
                                  encoding: 'utf-8',
                                ),
                                initialSettings: InAppWebViewSettings(
                                  javaScriptEnabled: true,
                                  mediaPlaybackRequiresUserGesture: false,
                                  allowsInlineMediaPlayback: true,
                                  supportMultipleWindows: false,
                                  javaScriptCanOpenWindowsAutomatically: false,
                                  disableVerticalScroll: true,
                                  disableHorizontalScroll: true,
                                  transparentBackground: false,
                                  allowsBackForwardNavigationGestures: false,
                                  allowsLinkPreview: false,
                                  isFraudulentWebsiteWarningEnabled: false,
                                  mixedContentMode: MixedContentMode
                                      .MIXED_CONTENT_ALWAYS_ALLOW,
                                  userAgent:
                                      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
                                ),
                                shouldOverrideUrlLoading:
                                    (controller, navigationAction) async {
                                  final url =
                                      navigationAction.request.url.toString();

                                  // Explicit allow-list — everything else is cancelled
                                  // (covers both iOS WKWebView iframe and Android WebView)
                                  final allowedPatterns = [
                                    'tiktok.com/embed',
                                    'embed.tiktok.com',
                                    'embed.js',
                                    'lf16-tiktok',
                                    'musical.ly',
                                    'byteoversea',
                                    'byteimg',
                                    'ibytedtos',
                                  ];

                                  for (final pattern in allowedPatterns) {
                                    if (url.contains(pattern)) {
                                      return NavigationActionPolicy.ALLOW;
                                    }
                                  }

                                  if (url.startsWith('data:') ||
                                      url.startsWith('about:')) {
                                    return NavigationActionPolicy.ALLOW;
                                  }

                                  return NavigationActionPolicy.CANCEL;
                                },
                                onCreateWindow:
                                    (controller, createWindowAction) async {
                                  return false;
                                },
                              )
                            : _buildVideoPlaceholder(context, videoUrl),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Activity name card (left strip) ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: Palette.cardShadow,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 4, color: Palette.sky),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.fitness_center_rounded,
                                          color: Palette.sky, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .videodetail_activityNameLabel,
                                        style: AppTextStyles.label(13,
                                            color: Palette.sky),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    style: AppTextStyles.heading(18,
                                        color: Palette.text),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── How to play (collapsible) ──
                  GestureDetector(
                    onTap: () => setState(
                        () => _howToPlayExpanded = !_howToPlayExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: Palette.cardShadow,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.help_outline_rounded,
                              color: Palette.sky, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .videodetail_howToPlayLabel,
                              style:
                                  AppTextStyles.heading(16, color: Palette.sky),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _howToPlayExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.keyboard_arrow_down,
                                color: Palette.sky, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: Palette.cardShadow,
                        border: Border.all(
                            color: Palette.sky.withValues(alpha: 0.25)),
                      ),
                      child: Text(content, style: AppTextStyles.body(15)),
                    ),
                    crossFadeState: _howToPlayExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                  const SizedBox(height: 16),
                  InfoBadges(activity: activity),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Sticky bottom buttons
          Container(
            decoration: BoxDecoration(
              color: Palette.cream,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    // START
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // pauseAllMediaPlayback is iOS-only
                          if (Platform.isIOS)
                            await _webController?.pauseAllMediaPlayback();
                          if (!context.mounted) return;
                          Navigator.pushNamed(
                            context,
                            AppRoutes.physicalActivity,
                            arguments: {
                              'activity': activity,
                              'extraChildIds': _extraChildIds,
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Palette.sky, Color(0xFF0DA8F4)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: Palette.buttonShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    AppLocalizations.of(context)!.common_start,
                                    style: AppTextStyles.heading(18,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ADD CHILD
                    Expanded(
                      child: GestureDetector(
                        onTap: _showChildPicker,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _extraChildIds.isEmpty
                                ? Colors.white
                                : Palette.sky.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _extraChildIds.isEmpty
                                  ? Colors.grey.shade300
                                  : Palette.sky,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _extraChildIds.isEmpty
                                    ? Icons.group_add_outlined
                                    : Icons.group_rounded,
                                color: _extraChildIds.isEmpty
                                    ? Colors.grey
                                    : Palette.sky,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _extraChildIds.isEmpty
                                        ? AppLocalizations.of(context)!
                                            .videodetail_addBtn
                                        : AppLocalizations.of(context)!
                                            .physical_childrenAdded(
                                                _extraChildIds.length),
                                    style: AppTextStyles.heading(16,
                                        color: _extraChildIds.isEmpty
                                            ? Colors.grey
                                            : Palette.sky),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder(BuildContext context, String videoUrl) {
    return Container(
      color: Palette.deepGrey,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library,
              size: 60, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.videodetail_previewNotAvailable,
            style: AppTextStyles.heading(16, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (videoUrl.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.videodetail_openInBrowser,
              style: AppTextStyles.body(12, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse(videoUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: Text(AppLocalizations.of(context)!.videodetail_openTiktok,
                  style: AppTextStyles.heading(14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Palette.deepGrey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ] else
            Text(
              AppLocalizations.of(context)!.videodetail_noVideoUrl,
              style: AppTextStyles.body(12, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

String? _extractTikTokVideoId(String url) {
  final regex = RegExp(
    r'tiktok\.com\/(?:@[\w.]+\/video\/|v\/|t\/|.*\/)(\d+)',
    caseSensitive: false,
  );
  return regex.firstMatch(url)?.group(1);
}

String _buildTikTokBlockquote(String videoId) {
  return '<blockquote class="tiktok-embed" '
      'cite="https://www.tiktok.com/video/$videoId" '
      'data-video-id="$videoId" '
      'style="max-width:605px;min-width:325px;">'
      '<section></section></blockquote>'
      '<script async src="https://www.tiktok.com/embed.js"></script>';
}

String buildResponsiveTikTokHtml(String rawHtml) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { background: black; width: 100%; height: 100%; overflow: hidden; }
  .video-container { position: relative; width: 100%; height: 100%; overflow: hidden; background: black; }
  .tiktok-content {
    position: absolute; top: 50%; left: 50%;
    transform: translate(-50%, -42%) scale(1.25);
    width: 100%; height: 100%;
  }
  blockquote.tiktok-embed { margin:0!important; padding:0!important; max-width:100%!important; min-width:100%!important; width:100%!important; height:100%!important; border:none!important; background:black!important; }
  blockquote.tiktok-embed section { display: none !important; }
  iframe { width:100%!important; height:100%!important; border:none!important; display:block!important; }
  a, aside { display: none !important; }
  .top-blocker { position:absolute; top:0; left:0; right:0; height:40%; background:linear-gradient(to bottom, rgba(0,0,0,0.9) 0%, transparent 100%); z-index:100; pointer-events:none; }
  .right-blocker { position:absolute; top:10%; right:0; width:20%; height:75%; z-index:100; pointer-events:none; }
  .bottom-center-blocker { position:absolute; bottom:0; left:0; right:0; height:30%; background:linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.5) 60%, transparent 100%); z-index:100; pointer-events:none; }

  /* Cover overlay — shows thumbnail when paused/ended, pointer-events:none so
     touches still reach TikTok's own play button at bottom-left of the iframe */
  #cover-overlay {
    display: none;
    position: absolute;
    inset: 0;
    z-index: 200;
    background: black center/cover no-repeat;
    pointer-events: none;
  }
</style>
<script>
  document.addEventListener('click', function(e){var t=e.target;if(t.tagName==='A'||t.closest('a')){e.preventDefault();e.stopPropagation();return false;}},true);
  document.addEventListener('touchstart', function(e){var t=e.target;if(t.tagName==='A'||t.closest('a')){e.preventDefault();e.stopPropagation();return false;}},true);
  function adjustEmbed(){var f=document.querySelector('iframe');if(f)f.style.cssText='width:100%!important;height:100%!important;border:none!important;';document.querySelectorAll('section').forEach(function(s){s.style.display='none';});}
  new MutationObserver(adjustEmbed).observe(document.body,{childList:true,subtree:true});
  setInterval(adjustEmbed,300);

  function showCover() { document.getElementById('cover-overlay').style.display = 'block'; }
  function hideCover() { document.getElementById('cover-overlay').style.display = 'none'; }

  /* Listen for TikTok embed postMessage state events */
  window.addEventListener('message', function(evt) {
    try {
      var d = evt.data;
      if (typeof d === 'string') d = JSON.parse(d);
      if (!d || !d.type) return;
      if (d.type === 'onStateChange') {
        var s = d.data !== undefined ? d.data : d.value;
        if (s === 'playing' || s === 1 || s === 'play') { hideCover(); }
        else if (s === 'paused' || s === 2 || s === 'pause' ||
                 s === 'ended'  || s === 0 || s === 'end') { showCover(); }
      }
    } catch(ex) {}
  });
</script>
</head>
<body>
<div class="video-container">
  <div class="tiktok-content">$rawHtml</div>

  <!-- Cover overlay: shows thumbnail when paused/ended; pointer-events:none keeps TikTok play button accessible -->
  <div id="cover-overlay"></div>

  <div class="top-blocker"></div>
  <div class="right-blocker"></div>
  <div class="bottom-center-blocker"></div>
</div>
</body>
</html>
''';
}
