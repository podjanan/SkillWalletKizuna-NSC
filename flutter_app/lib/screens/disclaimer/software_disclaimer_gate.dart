import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

/// Blocks access to the app until the current disclaimer has been accepted.
class SoftwareDisclaimerGate extends StatefulWidget {
  const SoftwareDisclaimerGate({
    required this.child,
    this.preferences,
    super.key,
  });

  final Widget child;
  final SharedPreferences? preferences;

  static const agreementVersion = 1;
  static const _acceptedVersionKey = 'software_disclaimer_accepted_version';

  @override
  State<SoftwareDisclaimerGate> createState() => _SoftwareDisclaimerGateState();
}

class _SoftwareDisclaimerGateState extends State<SoftwareDisclaimerGate> {
  SharedPreferences? _preferences;
  bool _isLoading = true;
  bool _hasAccepted = false;
  bool _confirmedReading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAcceptance();
  }

  Future<void> _loadAcceptance() async {
    final preferences =
        widget.preferences ?? await SharedPreferences.getInstance();
    final acceptedVersion = preferences.getInt(
      SoftwareDisclaimerGate._acceptedVersionKey,
    );

    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _hasAccepted = acceptedVersion == SoftwareDisclaimerGate.agreementVersion;
      _isLoading = false;
    });
  }

  Future<void> _accept() async {
    if (!_confirmedReading || _isSaving) return;
    setState(() => _isSaving = true);

    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setInt(
      SoftwareDisclaimerGate._acceptedVersionKey,
      SoftwareDisclaimerGate.agreementVersion,
    );

    if (!mounted) return;
    setState(() {
      _hasAccepted = true;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasAccepted) return widget.child;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: Palette.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Palette.terracotta,
                              Palette.terracottaDark,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.disclaimer_title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heading(20,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: _DisclaimerContent(),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            top: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Column(
                          children: [
                            Material(
                              type: MaterialType.transparency,
                              child: CheckboxListTile(
                                value: _confirmedReading,
                                onChanged: _isSaving
                                    ? null
                                    : (value) => setState(
                                          () => _confirmedReading =
                                              value ?? false,
                                        ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                activeColor: Palette.terracotta,
                                title: Text(
                                  AppLocalizations.of(context)!
                                      .disclaimer_acceptCheck,
                                  style: AppTextStyles.body(
                                    14,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _confirmedReading && !_isSaving
                                    ? _accept
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.terracotta,
                                  foregroundColor: Colors.white,
                                ),
                                icon: _isSaving
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(AppLocalizations.of(context)!
                                    .disclaimer_acceptButton),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclaimerContent extends StatelessWidget {
  const _DisclaimerContent();

  static const _bodyStyle = TextStyle(
    color: Color(0xFF374151),
    fontSize: 14,
    height: 1.55,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.disclaimer_intro,
          style: _bodyStyle,
        ),
        const SizedBox(height: 18),
        _SectionTitle(l.disclaimer_developers),
        const SizedBox(height: 8),
        _PersonRow(l.disclaimer_developer1),
        _PersonRow(l.disclaimer_developer2),
        _PersonRow(l.disclaimer_developer3),
        const SizedBox(height: 16),
        _SectionTitle(l.disclaimer_advisor),
        const SizedBox(height: 8),
        _PersonRow(l.disclaimer_advisorName),
        const SizedBox(height: 18),
        _SectionTitle(l.disclaimer_terms),
        const SizedBox(height: 8),
        Text(
          l.disclaimer_license,
          style: _bodyStyle,
        ),
        const SizedBox(height: 10),
        Text(
          l.disclaimer_liability,
          style: _bodyStyle,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Palette.terracottaDark,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child:
                Icon(Icons.person_outline, size: 18, color: Palette.terracotta),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: _DisclaimerContent._bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}
