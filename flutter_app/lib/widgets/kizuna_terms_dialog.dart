import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_text_styles.dart';
import '../theme/palette.dart';

const _privacyPolicyUrl =
    'https://krxton.github.io/Skill-Wallet-Kizuna/privacy-policy.html';
const _termsOfServiceUrl =
    'https://krxton.github.io/Skill-Wallet-Kizuna/terms-of-service.html';

Future<bool> showKizunaTermsDialog(
  BuildContext context, {
  VoidCallback? onAgree,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Disclaimer',
              style: AppTextStyles.heading(22, color: Palette.terracotta),
            ),
            const SizedBox(height: 14),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.body(14, color: Palette.authGrey),
                children: [
                  TextSpan(text: '${l10n.auth_tosDialogMsg}\n\n'),
                  TextSpan(text: l10n.auth_termsAgree),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: l10n.auth_termsOfService,
                    style: AppTextStyles.body(
                      14,
                      color: Palette.terracotta,
                      weight: FontWeight.w700,
                    ).copyWith(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openUrl(_termsOfServiceUrl),
                  ),
                  TextSpan(text: ' ${l10n.auth_and} '),
                  TextSpan(
                    text: l10n.auth_privacyPolicy,
                    style: AppTextStyles.body(
                      14,
                      color: Palette.terracotta,
                      weight: FontWeight.w700,
                    ).copyWith(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openUrl(_privacyPolicyUrl),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.authGrey,
                      side: const BorderSide(color: Palette.authGrey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.common_cancel,
                      style: AppTextStyles.heading(14, color: Palette.authGrey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx, true);
                      onAgree?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.terracotta,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.auth_enter,
                      style: AppTextStyles.heading(14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return agreed ?? false;
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
