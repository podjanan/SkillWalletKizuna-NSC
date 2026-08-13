import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

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
  State<SoftwareDisclaimerGate> createState() =>
      _SoftwareDisclaimerGateState();
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
      _hasAccepted =
          acceptedVersion == SoftwareDisclaimerGate.agreementVersion;
      _isLoading = false;
    });
  }

  Future<void> _accept() async {
    if (!_confirmedReading || _isSaving) return;
    setState(() => _isSaving = true);

    final preferences =
        _preferences ?? await SharedPreferences.getInstance();
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
                              'ข้อตกลงในการใช้ซอฟต์แวร์',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heading(20, color: Colors.white),
                            ),
                            Text(
                              'Software Disclaimer & License Agreement',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(
                                12,
                                color: Colors.white70,
                                weight: FontWeight.w600,
                              ),
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
                            CheckboxListTile(
                              value: _confirmedReading,
                              onChanged: _isSaving
                                  ? null
                                  : (value) => setState(
                                        () => _confirmedReading = value ?? false,
                                      ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              activeColor: Palette.terracotta,
                              title: Text(
                                'ฉันได้อ่าน เข้าใจ และยอมรับข้อตกลงข้างต้น',
                                style: AppTextStyles.body(
                                  14,
                                  weight: FontWeight.w700,
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
                                label: const Text('ยอมรับและดำเนินการต่อ'),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ซอฟต์แวร์ Skill Wallet Kizuna เป็นผลงานที่พัฒนาขึ้นภายใต้โครงการ “การแข่งขันพัฒนาโปรแกรมคอมพิวเตอร์แห่งประเทศไทย ครั้งที่ 28 (NSC 2026)” โดยมีวัตถุประสงค์เพื่อส่งเสริมการเรียนรู้และการพัฒนาทักษะของเด็กผ่านกิจกรรมในครอบครัว',
          style: _bodyStyle,
        ),
        SizedBox(height: 18),
        _SectionTitle('ผู้พัฒนา (Developers)'),
        SizedBox(height: 8),
        _PersonRow('นายกนก กลิ่นสุวรรณ์', 'Mr. Kanok Klinsuwan'),
        _PersonRow('นายพจนัณท์ โอสถานันท์', 'Mr. Podjanan Osatanan'),
        _PersonRow('นายนวพล กิตินันท์ประกร', 'Mr. Nawapon Kitinanprakorn'),
        SizedBox(height: 16),
        _SectionTitle('อาจารย์ที่ปรึกษา (Advisor)'),
        SizedBox(height: 8),
        _PersonRow(
          'ผู้ช่วยศาสตราจารย์ ดร.สุวัจชัย กมลสันติโรจน์',
          'Asst. Prof. Dr. Suwatchai Kamonsantiroj',
        ),
        SizedBox(height: 18),
        _SectionTitle('ข้อตกลงการใช้งาน'),
        SizedBox(height: 8),
        Text(
          'ทรัพย์สินทางปัญญาของซอฟต์แวร์นี้เป็นของผู้พัฒนา และผู้พัฒนาอนุญาตให้สำนักงานพัฒนาวิทยาศาสตร์และเทคโนโลยีแห่งชาติ (สวทช.) เผยแพร่ซอฟต์แวร์นี้แก่ผู้อื่นในลักษณะ “ตามสภาพ” (as is) เพื่อใช้เป็นการชั่วคราว แบบไม่ผูกขาด และเฉพาะเพื่อการศึกษา หรือวัตถุประสงค์ส่วนบุคคลที่ไม่ใช่เชิงพาณิชย์ โดยไม่มีค่าตอบแทน',
          style: _bodyStyle,
        ),
        SizedBox(height: 10),
        Text(
          'สวทช. และผู้พัฒนาไม่รับผิดชอบต่อความสูญเสีย ความเสียหาย ข้อผิดพลาด ประสิทธิภาพของซอฟต์แวร์ หรือผลใด ๆ ที่เกิดจากหรือเกี่ยวข้องกับการใช้งาน ผู้ใช้ต้องดูแล บำรุงรักษา และจัดการการใช้งานด้วยตนเอง',
          style: _bodyStyle,
        ),
        SizedBox(height: 18),
        _SectionTitle('License Agreement'),
        SizedBox(height: 8),
        Text(
          'This software is developed by the developers named above under the supervision of the advisor for the Skill Wallet Kizuna project. It is intended to encourage children and families to learn and practice skills through family activities.',
          style: _bodyStyle,
        ),
        SizedBox(height: 10),
        Text(
          'The intellectual property of this software belongs to its developers. The developers grant NSTDA permission to distribute the software on an “as is” basis for temporary, non-exclusive, non-commercial educational or personal use without remuneration. NSTDA and the developers are not responsible for any loss, damage, error, software efficiency, or consequence arising from its use. Users are responsible for operating and maintaining the software.',
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
  const _PersonRow(this.thaiName, this.englishName);

  final String thaiName;
  final String englishName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.person_outline, size: 18, color: Palette.terracotta),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$thaiName\n$englishName',
              style: _DisclaimerContent._bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}
