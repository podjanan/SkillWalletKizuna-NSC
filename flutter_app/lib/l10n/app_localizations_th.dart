// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get welcome_playBtn => 'เริ่มเล่น';

  @override
  String get welcome_signUpBtn => 'สมาชิกใหม่?';

  @override
  String get welcome_signInBtn => 'เข้าสู่ระบบ';

  @override
  String get home_categoryBtn => 'เลือกหมวดหมู่';

  @override
  String get home_physicalBtn => 'ด้านร่างกาย';

  @override
  String get home_languageBtn => 'ด้านภาษา';

  @override
  String get home_calculationBtn => 'ด้านการคำนวณ';

  @override
  String get home_cannotBtn => 'ไม่สามารถโหลดกิจกรรมยอดนิยมได้';

  @override
  String get home_nonewBtn => 'ไม่มีกิจกรรมใหม่เกิดขึ้น';

  @override
  String get home_noChildrenMsg =>
      'ยังไม่ได้เพิ่มลูก\nกรุณาเพิ่มลูกเพื่อเริ่มดูกิจกรรม';

  @override
  String get home_switchChild => 'เปลี่ยนลูก';

  @override
  String get draft_bannerTitle => 'กิจกรรมค้างอยู่';

  @override
  String get draft_bannerResume => 'ทำต่อ';

  @override
  String get draft_bannerDiscard => 'ลบทิ้ง';

  @override
  String get draft_discardTitle => 'ลบ progress ทิ้ง?';

  @override
  String get draft_discardMsg => 'ความคืบหน้าของกิจกรรมนี้จะถูกลบ';

  @override
  String get draft_leaveTitle => 'ออกจากกิจกรรม?';

  @override
  String get draft_leaveMsg =>
      'ความคืบหน้าจะถูกบันทึกไว้ คุณสามารถกลับมาทำต่อได้จากหน้าหลัก';

  @override
  String get draft_leaveBtn => 'บันทึกและออก';

  @override
  String get draft_conflictTitle => 'มีการบันทึกค้างอยู่';

  @override
  String draft_conflictMsg(String name) {
    return 'คุณมี progress ที่บันทึกไว้ของ \"$name\" อยู่ หากเริ่มกิจกรรมใหม่จะลบ progress นั้น';
  }

  @override
  String get draft_conflictPlay => 'เริ่มใหม่';

  @override
  String get common_discardChanges => 'ยกเลิกการเปลี่ยนแปลง?';

  @override
  String get common_discardMsg => 'การเปลี่ยนแปลงที่ยังไม่ได้บันทึกจะหายไป';

  @override
  String get common_discard => 'ยกเลิก';

  @override
  String get common_keepEditing => 'แก้ไขต่อ';

  @override
  String get home_popularactivityBtn => 'กิจกรรมยอดนิยม';

  @override
  String get home_newactivityBtn => 'กิจกรรมใหม่';

  @override
  String get home_viewallBtn => 'ดูทั้งหมด';

  @override
  String get home_searchBtn => 'ค้นหา...';

  @override
  String get home_bannerLanguage => 'ฝึกภาษา';

  @override
  String get home_bannerCalculate => 'คิดเลข';

  @override
  String get home_bannerProblems => 'แก้ปัญหา';

  @override
  String get home_filterTitle => 'กรองกิจกรรม';

  @override
  String get home_filterCategory => 'หมวดหมู่';

  @override
  String get home_filterLevel => 'ระดับ';

  @override
  String get home_filterAll => 'ทั้งหมด';

  @override
  String get home_filterEasy => 'ง่าย';

  @override
  String get home_filterMedium => 'กลาง';

  @override
  String get home_filterHard => 'ยาก';

  @override
  String get home_suggested => 'แนะนำ';

  @override
  String get parentprofile_postBtn => 'โพสต์';

  @override
  String get register_backBtn => 'ย้อนกลับ';

  @override
  String get register_signuptoBtn => 'ลงทะเบียนเข้าสู่';

  @override
  String get register_facebookBtn => 'ดำเนินการต่อด้วย FACEBOOK';

  @override
  String get register_googleBtn => 'ดำเนินการต่อด้วย GOOGLE';

  @override
  String get register_nextBtn => 'ต่อไป';

  @override
  String get register_registerBtn => 'ลงทะเบียน';

  @override
  String get register_additionalBtn => 'ข้อมูลเพิ่มเติม';

  @override
  String register_namesurnamechildBtn(Object index) {
    return 'ชื่อและนามสกุลคนที่ $index';
  }

  @override
  String get register_birthdayBtn => 'วันเกิด : วว/ดด/ปปปป';

  @override
  String get register_okBtn => 'เสร็จสิ้น';

  @override
  String get register_pls => 'กรอกข้อมูลให้ครบในรายการที่ ';

  @override
  String get register_finish => 'ลงทะเบียนสำเร็จ!';

  @override
  String get register_relation => 'ความสัมพันธ์';

  @override
  String get register_pickbirthday => 'เลือกวันเกิด';

  @override
  String get register_Anerroroccurredplstry =>
      'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง';

  @override
  String register_Anerroroccurred(Object index) {
    return 'เกิดข้อผิดพลาด: $index';
  }

  @override
  String register_sus(Object index) {
    return 'ลงทะเบียนสำเร็จ! เพิ่มลูก $index คน';
  }

  @override
  String register_submitterror(Object index) {
    return 'ส่งผิดพลาด: $index';
  }

  @override
  String register_requiredinformation(Object index) {
    return 'กรอกข้อมูลให้ครบ (ชื่อ, วันเกิด, ความสัมพันธ์) ในรายการที่ $index';
  }

  @override
  String get login_backBtn => 'ย้อนกลับ';

  @override
  String get login_facebookBtn => 'ดำเนินการต่อด้วย FACEBOOK';

  @override
  String get login_googleBtn => 'ดำเนินการต่อด้วย GOOGLE';

  @override
  String get login_loading => 'กำลังเข้าสู่ระบบ...';

  @override
  String get login_noAccount => 'ไม่พบบัญชีผู้ใช้ กรุณาลงทะเบียนก่อน';

  @override
  String get login_goToRegister => 'ไปลงทะเบียน';

  @override
  String get register_loading => 'กำลังลงทะเบียน...';

  @override
  String get register_alreadyExists =>
      'บัญชีนี้ลงทะเบียนแล้ว กรุณาเข้าสู่ระบบแทน';

  @override
  String get register_goToLogin => 'ไปเข้าสู่ระบบ';

  @override
  String get auth_termsAgree => 'ฉันได้อ่านและยอมรับ';

  @override
  String get auth_termsOfService => 'ข้อตกลงการใช้บริการ';

  @override
  String get auth_privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get auth_and => 'และ';

  @override
  String get auth_pleaseAgreeTerms =>
      'กรุณายอมรับข้อตกลงการใช้บริการและนโยบายความเป็นส่วนตัวก่อน';

  @override
  String get auth_loading => 'กำลังเข้าสู่ระบบ...';

  @override
  String get auth_tosDialogMsg =>
      'เพื่อให้มั่นใจว่าสิ่งต่างๆ เป็นไปเพื่อประโยชน์ของคุณ กรุณาอ่านข้อตกลงการใช้บริการก่อนเลือกเข้าใช้งาน';

  @override
  String get auth_readTos => 'อ่านข้อตกลง';

  @override
  String get auth_enter => 'เข้าใช้งาน';

  @override
  String get setting_backBtn => 'ย้อนกลับ';

  @override
  String get setting_settingBtn => 'การตั้งค่า';

  @override
  String get setting_personalBtn => 'ข้อมูลส่วนตัว';

  @override
  String get setting_generalBtn => 'ทั่วไป';

  @override
  String get setting_profileBtn => 'โปรไฟล์';

  @override
  String get setting_childBtn => 'เด็ก';

  @override
  String get setting_notificationBtn => 'การแจ้งเตือน';

  @override
  String get setting_thaiBtn => 'ภาษาไทย';

  @override
  String get setting_englishBtn => 'ภาษาอังกฤษ';

  @override
  String get setting_logoutBtn => 'ลงชื่อออก';

  @override
  String get setting_logoutTitle => 'ออกจากระบบ?';

  @override
  String get setting_logoutMsg => 'คุณต้องการออกจากระบบใช่ไหม?';

  @override
  String get setting_logoutConfirm => 'ออกจากระบบ';

  @override
  String get setting_deleteAccountBtn => 'ลบบัญชี';

  @override
  String get setting_deleteTitle => 'ลบบัญชีหรือไม่?';

  @override
  String get setting_deleteMsg =>
      'การดำเนินการนี้จะลบบัญชีและข้อมูลลูกทั้งหมดอย่างถาวร ข้อมูลจะถูกลบภายใน 30 วัน และไม่สามารถกู้คืนได้';

  @override
  String get setting_deleteConfirm => 'ลบบัญชี';

  @override
  String get setting_deleteSuccess => 'ลบบัญชีสำเร็จแล้ว';

  @override
  String get setting_deleteError => 'ไม่สามารถลบบัญชีได้ กรุณาลองใหม่อีกครั้ง';

  @override
  String get namesetting_changenameBtn => 'เปลี่ยนชื่อ';

  @override
  String get namesetting_enternewnameBtn => 'กรุณากรอกชื่อใหม่';

  @override
  String get namesetting_hint => 'พิมพ์ชื่อของคุณ...';

  @override
  String get namesetting_saveBtn => 'บันทึก';

  @override
  String get profilesetting_nameBtn => 'ชื่อ';

  @override
  String get profilesetting_deleteaccoutBtn => 'ลบบัญชี';

  @override
  String get profileSet_deleteDialogTitle => 'ยืนยันการลบบัญชี';

  @override
  String get profilesetting_areusureBtn =>
      'คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีของคุณ? การกระทำนี้ไม่สามารถย้อนกลับได้';

  @override
  String get profilesetting_cancelBtn => 'ยกเลิก';

  @override
  String get profilesetting_deleteBtn => 'ลบบัญชี';

  @override
  String get childprofile_mathGame => 'เกมคณิตศาสตร์';

  @override
  String get childprofile_workoutGame => 'เกมออกกำลังกาย';

  @override
  String get childsetting_childsettingBtn => 'การตั้งค่าเด็ก';

  @override
  String get childsetting_scoreBtn => 'คะแนน';

  @override
  String get childsetting_viewprofileBtn => 'ดูโปรไฟล์';

  @override
  String get childsetting_manageBtn => 'จัดการ';

  @override
  String get childgallery_title => 'แกลเลอรีของฉัน';

  @override
  String get childgallery_empty => 'ยังไม่มีรูปภาพ';

  @override
  String get history_timesSuffix => 'ครั้ง';

  @override
  String get result_title => 'ผลการเล่น';

  @override
  String get result_timeUsedTitle => 'เวลาที่ใช้';

  @override
  String get redemption_playBtn => 'เล่น';

  @override
  String get redemption_rewardIceCream => 'ไอศกรีม';

  @override
  String get redemption_rewardPlaytime => 'เล่นเกม 1 ชม.';

  @override
  String get redemption_rewardToy => 'ของเล่นใหม่';

  @override
  String get redemption_rewardStickers => 'สติ๊กเกอร์';

  @override
  String get redemption_historyPlayedDefault => 'เล่นปิงปอง';

  @override
  String get redemption_historyRedeemedDefault => 'แลกไอศกรีม';

  @override
  String get dialog_deleteTitle => 'ลบโปรไฟล์?';

  @override
  String get dialog_deleteContent =>
      'คุณแน่ใจหรือไม่ที่จะลบโปรไฟล์นี้? การกระทำนี้ไม่สามารถย้อนกลับได้';

  @override
  String get dialog_confirmDelete => 'ลบ';

  @override
  String get dialog_cancel => 'ยกเลิก';

  @override
  String get dialog_saveSuccess => 'บันทึกสำเร็จ!';

  @override
  String get notificationsetting_notificationBtn => 'การแจ้งเตือน';

  @override
  String get notificationsetting_allnotificationBtn => 'การแจ้งเตือนทั้งหมด';

  @override
  String get notificationsetting_postBtn => 'โพสต์';

  @override
  String get notificationsetting_likeBtn => 'การถูกใจ';

  @override
  String get notificationsetting_commentBtn => 'การแสดงความคิดเห็น';

  @override
  String get videodetail_activitynameBtn => 'ชื่อกิจกรรม';

  @override
  String get videodetail_nameBtn => 'ชื่อ';

  @override
  String get videodetail_DescriptionBtn => 'คำอธิบาย';

  @override
  String get videodetail_descriptionBtn => 'คำอธิบาย';

  @override
  String get videodetail_howtoplayBtn => 'วิธีเล่น / คำแนะนำ:';

  @override
  String get videodetail_contentBtn => 'เนื้อหา';

  @override
  String get videodetail_startBtn => 'เริ่ม';

  @override
  String get videodetail_addBtn => 'เพิ่ม';

  @override
  String get videodetail_videoNotAvailable =>
      'ไม่สามารถเล่นวิดีโอได้ (ไม่มีเนื้อหา HTML)';

  @override
  String get videodetail_activityNameLabel => 'ชื่อกิจกรรม:';

  @override
  String get videodetail_descriptionLabel => 'รายละเอียด:';

  @override
  String get videodetail_howToPlayLabel => 'วิธีการเล่น / คำแนะนำ:';

  @override
  String get videodetail_categoryPrefix => 'หมวดหมู่: ';

  @override
  String get videodetail_difficultyPrefix => 'ความยาก: ';

  @override
  String get videodetail_maxScorePrefix => 'คะแนนสูงสุด: ';

  @override
  String get addchild_namesurnameBtn => 'ชื่อและนามสกุล (เด็ก)';

  @override
  String get addchild_errorName => 'กรุณาระบุชื่อ';

  @override
  String get addchild_birthdayBtn => 'วันเกิด : วว/ดด/ปปปป';

  @override
  String get addchild_okBtn => 'OK';

  @override
  String get addchild_logoutTitle => 'ออกจากระบบ?';

  @override
  String get addchild_logoutMsg =>
      'กรุณาเพิ่มลูกอย่างน้อย 1 คนก่อนใช้งานแอป คุณต้องการออกจากระบบหรือไม่?';

  @override
  String get addchild_errorRequiredFields =>
      'กรุณากรอกข้อมูลให้ครบทุกช่อง (ชื่อ, วันเกิด, ความสัมพันธ์)';

  @override
  String get childnamesetting_editnameBtn => 'แก้ไขชื่อ';

  @override
  String get childnamesetting_saveBtn => 'บันทึก';

  @override
  String get managechild_manageprofileBtn => 'จัดการโปรไฟล์';

  @override
  String get managechild_nameBtn => 'ชื่อ';

  @override
  String get managechild_medalsandredemptionBtn => 'รางวัลและการแลกรางวัล';

  @override
  String get managechild_deleteprofileBtn => 'ลบโปรไฟล์';

  @override
  String get dairyactivity_playhistoryBtn => 'ประวัติการเล่น';

  @override
  String get dairyactivity_timeBtn => 'เวลา';

  @override
  String get dairyactivity_medalsBtn => 'รางวัล';

  @override
  String get medalredemption_addrewardBtn => 'เพิ่มข้อตกลง';

  @override
  String get medalredemption_rewardnameBtn => 'ชื่อข้อตกลง';

  @override
  String get medalredemption_costBtn => 'คะแนน';

  @override
  String get medalredemption_cancelBtn => 'ยกเลิก';

  @override
  String get medalredemption_addBtn => 'เพิ่ม';

  @override
  String get medalredemption_redemptionBtn => 'ข้อตกลง';

  @override
  String get medalredemption_activitiesBtn => 'กิจกรรม';

  @override
  String get medalredemption_currentscoreBtn => 'คะแนนปัจจุบัน';

  @override
  String get medalredemption_rewardshopBtn => 'ข้อตกลง';

  @override
  String get medalredemption_successfullyBtn => 'แลกรางวัลสำเร็จ';

  @override
  String get agreement_typeTime => 'เวลา';

  @override
  String get agreement_typeItem => 'สิ่งของ';

  @override
  String get agreement_typePrivilege => 'สิทธิพิเศษ';

  @override
  String get agreement_typeFamily => 'กิจกรรมครอบครัว';

  @override
  String get agreement_selectType => 'เลือกประเภทข้อตกลง';

  @override
  String get agreement_confirmTitle => 'ยืนยันข้อตกลง';

  @override
  String agreement_confirmMsg(int cost, String name) {
    return 'ใช้ $cost คะแนนเพื่อแลก \"$name\"?';
  }

  @override
  String get agreement_confirmBtn => 'ยืนยัน';

  @override
  String get agreement_sessionActive => 'กำลังใช้งาน';

  @override
  String get agreement_timeRemaining => 'เวลาที่เหลือ';

  @override
  String get agreement_startTimer => 'เริ่ม';

  @override
  String get agreement_stopTimer => 'หยุด';

  @override
  String get agreement_endSession => 'สิ้นสุดการใช้งาน';

  @override
  String get agreement_sessionComplete => 'เสร็จสิ้น!';

  @override
  String get agreement_behaviorTitle => 'พฤติกรรมเป็นอย่างไร?';

  @override
  String get agreement_behaviorGood => 'ดี';

  @override
  String get agreement_behaviorOk => 'ปกติ';

  @override
  String get agreement_behaviorBad => 'ต้องปรับปรุง';

  @override
  String agreement_bonusMsg(int points) {
    return 'โบนัส: +$points คะแนน';
  }

  @override
  String agreement_deductMsg(int points) {
    return 'หัก: -$points คะแนน';
  }

  @override
  String get agreement_noChange => 'ไม่มีการเปลี่ยนแปลงคะแนน';

  @override
  String agreement_notEnoughPoints(int needed) {
    return 'คะแนนไม่เพียงพอ! ต้องการอีก $needed คะแนน';
  }

  @override
  String get agreement_durationLabel => 'ระยะเวลา (นาที)';

  @override
  String get agreement_emptyList => 'ยังไม่มีข้อตกลง';

  @override
  String get agreement_emptyHint => 'กด + เพื่อสร้างข้อตกลงใหม่';

  @override
  String get physical_snackNoEvidence => 'กรุณาแนบวิดีโอหรือรูปภาพหลักฐาน';

  @override
  String physical_snackInvalidScore(int maxScore) {
    return 'กรุณาระบุคะแนนให้ถูกต้อง (1 ถึง $maxScore)';
  }

  @override
  String get physical_dialogSubmitTitle => 'ส่งข้อมูลเรียบร้อย!';

  @override
  String get physical_dialogSubmitContent =>
      'หลักฐานของคุณถูกส่งเพื่อรอการอนุมัติแล้ว';

  @override
  String get physical_dialogOkBtn => 'ตกลง';

  @override
  String physical_snackSubmitError(String error) {
    return 'เกิดข้อผิดพลาดในการส่ง: $error';
  }

  @override
  String get physical_dialogEnterScoreTitle => 'ระบุคะแนน';

  @override
  String physical_dialogEnterScoreHint(int maxScore) {
    return 'ใส่คะแนน (1-$maxScore)';
  }

  @override
  String get physical_dialogCancelBtn => 'ยกเลิก';

  @override
  String physical_snackInvalidInput(int maxScore) {
    return 'กรุณาใส่คะแนนให้ถูกต้อง (0-$maxScore)';
  }

  @override
  String get physical_stopBtn => 'หยุด';

  @override
  String get physical_startBtn => 'เริ่ม';

  @override
  String get physical_takePhotoBtn => 'ถ่ายรูป';

  @override
  String get physical_medalsScoreLabel => 'เหรียญรางวัล / คะแนน';

  @override
  String get physical_diaryLabel => 'บันทึกประจำวัน';

  @override
  String get physical_diaryHint => 'เขียนบันทึกที่นี่...';

  @override
  String get physical_imageEvidenceLabel => 'หลักฐานรูปภาพ';

  @override
  String get physical_videoEvidenceLabel => 'หลักฐานวิดีโอ';

  @override
  String get physical_timeLabel => 'เวลา';

  @override
  String get physical_submittingBtn => 'กำลังส่งข้อมูล...';

  @override
  String get physical_finishBtn => 'เสร็จสิ้น';

  @override
  String get physical_addChildren => 'เพิ่มเด็ก';

  @override
  String get physical_addChildrenDesc => 'เลือกเด็กที่จะเล่นด้วยกัน';

  @override
  String physical_childrenAdded(int count) {
    return '+$count คน';
  }

  @override
  String get physical_currentChild => 'กำลังเล่นอยู่';

  @override
  String get physical_confirm => 'ยืนยัน';

  @override
  String get languagedetail_titlePrefix => 'ภาษา: ';

  @override
  String get languagedetail_categoryPrefix => 'หมวดหมู่: ';

  @override
  String get languagedetail_activityTitleLabel => 'หัวข้อกิจกรรม';

  @override
  String get languagedetail_descriptionLabel => 'รายละเอียด';

  @override
  String get languagedetail_difficultyPrefix => 'ความยาก: ';

  @override
  String get languagedetail_maxScorePrefix => 'คะแนนสูงสุด: ';

  @override
  String get languagedetail_startBtn => 'เริ่ม';

  @override
  String get languagedetail_openInYoutube => 'เปิดใน YouTube (ทีวี)';

  @override
  String get itemintro_recordToEnable => 'กดบันทึกเสียงเพื่อฟังเสียงของคุณ';

  @override
  String get itemintro_listenExampleBtn => 'ฟังตัวอย่าง';

  @override
  String get itemintro_practiceNowBtn => 'เริ่มฝึกทันที';

  @override
  String get itemintro_submitBtn => 'ส่งผลงาน';

  @override
  String get itemintro_playsection => 'เล่นข้อความ';

  @override
  String get itemintro_record => 'บันทึก';

  @override
  String get itemintro_casttotv => 'ส่งไปยังทีวี';

  @override
  String get itemintro_airplay => 'เล่นทางอากาศ';

  @override
  String get itemintro_previous => '< ก่อนหน้า';

  @override
  String get itemintro_next => 'ถัดไป >';

  @override
  String get itemintro_finish => 'เสร็จสิ้น >';

  @override
  String get itemintro_Videonotavailable => 'ไม่มีวิดีโอ';

  @override
  String get record_loading => 'กำลังโหลด...';

  @override
  String get record_finishBtn => 'เสร็จสิ้น';

  @override
  String get record_errorMic => 'เกิดข้อผิดพลาดหรือไมโครโฟนไม่ได้รับอนุญาต';

  @override
  String get record_statusRecording => 'กำลังบันทึกเสียง...';

  @override
  String get record_statusIdle => 'กดไมค์เพื่อเริ่มอัดเสียง';

  @override
  String get result_activityCompletedDefault => 'กิจกรรมเสร็จสมบูรณ์';

  @override
  String get result_greatJobTitle => 'ยอดเยี่ยมมาก!';

  @override
  String get result_totalScoreLabel => 'คะแนนรวม';

  @override
  String get result_timeSpentLabel => 'เวลาที่ใช้';

  @override
  String get result_retryBtn => 'ลองใหม่';

  @override
  String get result_backToActivitiesBtn => 'กลับไปหน้ากิจกรรม';

  @override
  String get result_returnHomeBtn => 'กลับหน้าหลัก';

  @override
  String result_timeFormat(int minutes, int seconds) {
    return '$minutes นาที $seconds วินาที';
  }

  @override
  String get calculate_title => 'คำนวณ';

  @override
  String get calculate_plusBtn => 'บวก +';

  @override
  String get calculate_minusBtn => 'ลบ -';

  @override
  String get calculate_multiplyBtn => 'คูณ *';

  @override
  String get calculate_divideBtn => 'หาร /';

  @override
  String get calculate_mixBtn => 'ผสม + - * /';

  @override
  String get languagehub_searchHint => 'ค้นหา...';

  @override
  String get languagehub_trainingTitle => 'ฝึกฝนภาษา';

  @override
  String get languagehub_listeningSpeakingTitle => 'การฟังและการพูด';

  @override
  String get languagehub_easyBtn => 'ง่าย';

  @override
  String get languagehub_mediumBtn => 'ปานกลาง';

  @override
  String get languagehub_difficultBtn => 'ยาก';

  @override
  String get plus_castToTvBtn => 'ขึ้นจอทีวี';

  @override
  String get plus_answerBtn => 'ดูเฉลย';

  @override
  String get createpost_sharesus => 'แชร์โพสต์เรียบร้อย!';

  @override
  String get createpost_error => 'เกิดข้อผิดพลาด:';

  @override
  String get createpost_newpost => 'โพสต์ใหม่';

  @override
  String get createpost_share => 'แชร์';

  @override
  String get createpost_picksomepicture => 'แตะเพื่อเลือกรูป';

  @override
  String get createpost_changepic => 'เปลี่ยนรูป';

  @override
  String get createpost_writecaption => 'เขียนคำบรรยาย...';

  @override
  String get languagelist_snackNotConnected =>
      'ส่วนนี้ยังไม่ได้เชื่อมต่อกับกิจกรรมจริง';

  @override
  String get common_categoryLabel => 'หมวดหมู่';

  @override
  String get common_difficultyLabel => 'ความยาก';

  @override
  String get common_maxScoreLabel => 'คะแนนสูงสุด';

  @override
  String get common_categoryLanguage => 'ด้านภาษา';

  @override
  String get common_categoryPhysical => 'ด้านร่างกาย';

  @override
  String get common_categoryCalculate => 'ด้านคำนวณ';

  @override
  String get common_activityLanguage => 'กิจกรรมภาษา';

  @override
  String get common_activityPhysical => 'กิจกรรมร่างกาย';

  @override
  String get common_activityCalculate => 'กิจกรรมคำนวณ';

  @override
  String get common_difficultyEasy => 'ง่าย';

  @override
  String get common_difficultyMedium => 'ปานกลาง';

  @override
  String get common_difficultyHard => 'ยาก';

  @override
  String get createActivity_title => 'สร้างกิจกรรม';

  @override
  String get createActivity_selectCategory => 'เลือกหมวดหมู่';

  @override
  String get createActivity_physical => 'ด้านร่างกาย';

  @override
  String get createActivity_calculate => 'ด้านคำนวณ';

  @override
  String get createActivity_name => 'ชื่อกิจกรรม';

  @override
  String get createActivity_description => 'คำอธิบาย';

  @override
  String get createActivity_content => 'วิธีเล่น / คำแนะนำ';

  @override
  String get createActivity_difficulty => 'ระดับความยาก';

  @override
  String get createActivity_maxScore => 'คะแนนสูงสุด';

  @override
  String get createActivity_videoUrl => 'URL วิดีโอ (TikTok)';

  @override
  String get createActivity_addQuestion => 'เพิ่มโจทย์';

  @override
  String get createActivity_question => 'คำถาม';

  @override
  String get createActivity_answer => 'คำตอบ';

  @override
  String get createActivity_solution => 'วิธีทำ / อธิบาย';

  @override
  String get createActivity_score => 'คะแนน';

  @override
  String get createActivity_submit => 'สร้าง';

  @override
  String get createActivity_success => 'สร้างกิจกรรมสำเร็จ!';

  @override
  String get createActivity_error => 'ไม่สามารถสร้างกิจกรรมได้';

  @override
  String get createActivity_nameRequired => 'กรุณาระบุชื่อกิจกรรม';

  @override
  String get createActivity_contentRequired => 'กรุณาระบุวิธีเล่น';

  @override
  String get createActivity_needQuestions => 'กรุณาเพิ่มโจทย์อย่างน้อย 1 ข้อ';

  @override
  String createActivity_questionNo(int index) {
    return 'โจทย์ที่ $index';
  }

  @override
  String get createActivity_removeQuestion => 'ลบ';

  @override
  String get createActivity_creating => 'กำลังสร้าง...';

  @override
  String get profile_myActivities => 'กิจกรรมของฉัน';

  @override
  String get profile_noActivities => 'ยังไม่มีกิจกรรม';

  @override
  String get profile_editActivity => 'แก้ไขกิจกรรม';

  @override
  String get profile_deleteActivity => 'ลบกิจกรรม';

  @override
  String profile_deleteConfirm(String name) {
    return 'คุณแน่ใจหรือไม่ว่าต้องการลบ \"$name\"?';
  }

  @override
  String get profile_deleteSuccess => 'ลบกิจกรรมแล้ว';

  @override
  String get profile_updateSuccess => 'อัปเดตกิจกรรมแล้ว';

  @override
  String get profile_save => 'บันทึก';

  @override
  String get profile_manage => 'จัดการ';

  @override
  String get share_title => 'แชร์ผลลัพธ์';

  @override
  String get share_asImage => 'รูปภาพ';

  @override
  String get share_asText => 'ข้อความ';

  @override
  String get share_greatJob => 'ยอดเยี่ยม!';

  @override
  String get share_keepTrying => 'สู้ต่อไป!';

  @override
  String share_textTemplate(String activityName, int score, int maxScore) {
    return 'ฉันได้ $score/$maxScore คะแนนจากกิจกรรม \"$activityName\" ใน Skill Wallet Kizuna!';
  }

  @override
  String get common_loginFailed => 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองอีกครั้ง';

  @override
  String common_errorGeneric(String msg) {
    return 'ข้อผิดพลาด: $msg';
  }

  @override
  String get common_error => 'ข้อผิดพลาด';

  @override
  String get common_processing => 'กำลังดำเนินการ...';

  @override
  String get common_retry => 'ลองอีกครั้ง';

  @override
  String get common_cancel => 'ยกเลิก';

  @override
  String get common_close => 'ปิด';

  @override
  String get common_noServer => 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์';

  @override
  String get audio_tooShort => 'ข้อมูลเสียงสั้นเกินไป — ลองอีกครั้ง';

  @override
  String get audio_notFound => 'ไม่พบไฟล์เสียง — ลองอีกครั้ง';

  @override
  String get audio_analyseFailed => 'วิเคราะห์ไม่สำเร็จ — ลองอีกครั้ง';

  @override
  String get calculate_restartTitle => 'เริ่มใหม่?';

  @override
  String get calculate_restartMsg => 'เวลาและคำตอบจะถูกรีเซ็ต';

  @override
  String get calculate_restartBtn => 'เริ่มใหม่';

  @override
  String calculate_solutionTitle(int index) {
    return 'ข้อที่ #$index';
  }

  @override
  String get calculate_questionLabel => 'โจทย์:';

  @override
  String get calculate_answerLabel => 'คำตอบ:';

  @override
  String get calculate_pressStart => 'กดปุ่มเริ่มเพื่อจับเวลา';

  @override
  String get calculate_questionsAfterTimer => 'โจทย์จะแสดงหลังจากจับเวลาเสร็จ';

  @override
  String calculate_failedPickFile(String error) {
    return 'เลือกไฟล์ไม่สำเร็จ: $error';
  }

  @override
  String get calculate_childIdNotFound =>
      'ไม่พบรหัสเด็ก กรุณาเข้าสู่ระบบอีกครั้ง';

  @override
  String calculate_errorCompleting(String error) {
    return 'เกิดข้อผิดพลาดในการทำกิจกรรม: $error';
  }

  @override
  String get itemintro_videoLoading => 'กรุณารอสักครู่ กำลังโหลดวิดีโอ...';

  @override
  String get itemintro_timingIncomplete =>
      'ข้อมูลเวลาสำหรับประโยคนี้ไม่สมบูรณ์';

  @override
  String itemintro_videoPlayError(String error) {
    return 'ไม่สามารถเล่นวิดีโอได้: $error';
  }

  @override
  String get itemintro_micPermission => 'กรุณาอนุญาตการเข้าถึงไมโครโฟน';

  @override
  String itemintro_recordStartError(String error) {
    return 'ไม่สามารถเริ่มบันทึกเสียงได้: $error';
  }

  @override
  String get itemintro_recordTooShort =>
      'บันทึกเสียงสั้นเกินไป กรุณาลองอีกครั้ง';

  @override
  String itemintro_evalResult(int score, String text) {
    return 'ผลการประเมิน: $score% - \"$text\"';
  }

  @override
  String itemintro_questError(String error) {
    return 'เกิดข้อผิดพลาดในการทำกิจกรรม: $error';
  }

  @override
  String get itemintro_playbackFailed => 'ไม่สามารถเล่นเสียงที่บันทึกได้';

  @override
  String get record_micDenied => 'ไม่ได้รับอนุญาตให้ใช้ไมโครโฟน';

  @override
  String get record_recordingFailed => 'การบันทึกเสียงล้มเหลว';

  @override
  String get record_playbackFailed => 'ไม่สามารถเล่นเสียงได้';

  @override
  String get record_noValidAudio => 'ข้อผิดพลาด: ไม่มีเสียงที่บันทึกไว้';

  @override
  String record_aiError(String error) {
    return 'ข้อผิดพลาด AI: $error';
  }

  @override
  String get medals_noActivityHistory => 'ไม่มีประวัติกิจกรรม';

  @override
  String get medals_noHistory => 'ไม่มีประวัติ';

  @override
  String get post_noComments => 'ยังไม่มีความคิดเห็น เป็นคนแรกเลย!';

  @override
  String get namesetting_saveFailed =>
      'ไม่สามารถบันทึกชื่อได้ กรุณาลองอีกครั้ง';

  @override
  String get activityCard_selectChild => 'กรุณาเลือกเด็ก';

  @override
  String get activityCard_selectChildMsg =>
      'คุณต้องเลือกเด็กก่อนจึงจะสามารถเล่นกิจกรรมได้';

  @override
  String get activityCard_goSelect => 'ไปเลือกเด็ก';

  @override
  String get childsetting_addSuccess => 'เพิ่มเด็กสำเร็จ';

  @override
  String get childsetting_deleteSuccess => 'ลบเด็กสำเร็จ';

  @override
  String get childsetting_selectSuccess => 'เลือกเด็กสำเร็จ';

  @override
  String get childsetting_noChildren => 'ยังไม่มีเด็กในระบบ';

  @override
  String get childsetting_addChild => 'เพิ่มเด็ก';

  @override
  String get childsetting_active => 'กำลังใช้งาน';

  @override
  String get childsetting_select => 'เลือก';

  @override
  String get common_selectSource => 'เลือกแหล่ง';

  @override
  String get common_camera => 'กล้อง';

  @override
  String get common_gallery => 'แกลเลอรี';

  @override
  String get common_pickFromGallery => 'เลือกรูปจากแกลเลอรี';

  @override
  String get common_useGooglePhoto => 'ใช้รูปโปรไฟล์ Google';

  @override
  String get common_useFacebookPhoto => 'ใช้รูปโปรไฟล์ Facebook';

  @override
  String get common_useOriginalPhoto => 'ใช้รูปโปรไฟล์เดิม';

  @override
  String get common_uploadPhotoFailed => 'อัปโหลดรูปไม่สำเร็จ';

  @override
  String common_photoNotFound(String provider) {
    return 'ไม่พบรูปโปรไฟล์จาก $provider';
  }

  @override
  String get common_ok => 'ตกลง';

  @override
  String get common_submit => 'ส่ง';

  @override
  String get common_addImage => 'เพิ่มรูป';

  @override
  String get common_addVideo => 'เพิ่มวิดีโอ';

  @override
  String get common_videoAdded => 'เพิ่มวิดีโอแล้ว';

  @override
  String get common_image => 'รูปภาพ';

  @override
  String get common_video => 'วิดีโอ';

  @override
  String get common_howToPlay => 'วิธีเล่น';

  @override
  String get common_questions => 'คำถาม';

  @override
  String get common_evidence => 'หลักฐาน';

  @override
  String get common_finish => 'เสร็จสิ้น';

  @override
  String get common_start => 'เริ่ม';

  @override
  String get common_restart => 'เริ่มใหม่';

  @override
  String get common_done => 'เสร็จ';

  @override
  String get common_submitting => 'กำลังส่งข้อมูล...';

  @override
  String get common_score => 'คะแนน';

  @override
  String get calculate_noAnswer => 'ไม่มีเฉลย';

  @override
  String get calculate_answer => 'ตอบ';

  @override
  String get calculate_answerAgain => 'ตอบอีกครั้ง';

  @override
  String get calculate_stopBeforeAnswer => 'หยุดเวลาก่อนตอบ';

  @override
  String calculate_yourAnswer(String answer) {
    return 'คำตอบของคุณ: $answer';
  }

  @override
  String get calculate_typeAnswer => 'พิมพ์คำตอบ...';

  @override
  String get calculate_diaryNotes => 'บันทึก / โน้ต';

  @override
  String get calculate_writeNotes => 'เขียนบันทึกที่นี่...';

  @override
  String get calculate_noQuestions => 'ไม่มีคำถาม';

  @override
  String get calculate_confirmFinishTitle => 'หยุดจับเวลา?';

  @override
  String get calculate_confirmFinishMsg =>
      'คุณแน่ใจหรือไม่ว่าต้องการหยุด? ไม่สามารถเริ่มจับเวลาใหม่ได้';

  @override
  String get calculate_descriptionLabel => 'คำอธิบาย';

  @override
  String get calculate_solutionLabel => 'วิธีทำ:';

  @override
  String get calculate_correct => 'ถูก';

  @override
  String get calculate_incorrect => 'ผิด';

  @override
  String get record_title => 'บันทึกเสียง';

  @override
  String itemintro_segmentOf(int current, int total) {
    return 'ข้อ $current จาก $total';
  }

  @override
  String get itemintro_speak => 'พูด';

  @override
  String get itemintro_point => 'คะแนน';

  @override
  String get itemintro_completed => 'เสร็จแล้ว';

  @override
  String get itemintro_pausePlayback => 'หยุดเล่น...';

  @override
  String get itemintro_listenRecording => 'ฟังเสียงที่บันทึก';

  @override
  String get itemintro_recordToPlayback => 'กดบันทึกเสียงเพื่อฟังเสียงของคุณ';

  @override
  String get videodetail_previewNotAvailable =>
      'ไม่สามารถแสดงตัวอย่างวิดีโอได้';

  @override
  String get videodetail_openInBrowser => 'เปิดในเบราว์เซอร์เพื่อรับชม';

  @override
  String get videodetail_openTiktok => 'เปิด TIKTOK';

  @override
  String get videodetail_openInTiktokTV => 'เปิดใน TikTok (ทีวี)';

  @override
  String get videodetail_noVideoUrl => 'ไม่มีลิงก์วิดีโอ';

  @override
  String get calculate_tvMode => 'โหมดทีวี';

  @override
  String get calculate_tvModeHint => 'เลื่อนเพื่อดูข้อถัดไป';

  @override
  String get calculate_questionsCount => 'ข้อ';

  @override
  String get calculate_tvModeBannerTitle => 'แชร์ไปทีวี';

  @override
  String get calculate_tvModeBannerSub => 'แสดงโจทย์บนหน้าจอใหญ่';

  @override
  String get languagehub_appTitle => 'กระท่อน';

  @override
  String get languagehub_fillInBlanksTitle => 'เติมคำในช่องว่าง';

  @override
  String get result_resultTitle => 'ผลลัพธ์';

  @override
  String get result_totalScoreTitle => 'คะแนนรวม';

  @override
  String get result_keepTryingTitle => 'สู้ต่อไป!';

  @override
  String get result_timeSpentPrefix => 'เวลาที่ใช้: ';

  @override
  String get result_playAgainBtn => 'เล่นอีกครั้ง';

  @override
  String get plus_title => 'บวก +';

  @override
  String get plus_questionTitle => 'โจทย์';

  @override
  String get plus_startBtn => 'เริ่ม';

  @override
  String get answerplus_title => 'เฉลย บวก +';

  @override
  String get answerplus_questionLabel => 'โจทย์';

  @override
  String get answerplus_answerLabel => 'เฉลย';

  @override
  String get email_loginTitle => 'เข้าสู่ระบบด้วยอีเมล';

  @override
  String get email_registerTitle => 'สมัครสมาชิก';

  @override
  String get email_emailHint => 'อีเมล';

  @override
  String get email_passwordHint => 'รหัสผ่าน';

  @override
  String get email_nameHint => 'ชื่อ-นามสกุล';

  @override
  String get email_loginBtn => 'เข้าสู่ระบบ';

  @override
  String get email_registerBtn => 'สมัครสมาชิก';

  @override
  String get email_forgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get email_noAccount => 'ยังไม่มีบัญชี? สมัครสมาชิก';

  @override
  String get email_hasAccount => 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ';

  @override
  String get email_resetSent =>
      'ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว กรุณาตรวจสอบกล่องจดหมาย';

  @override
  String get email_passwordTooShort => 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';

  @override
  String get email_enterEmail => 'กรุณากรอกอีเมล';

  @override
  String get email_enterPassword => 'กรุณากรอกรหัสผ่าน';

  @override
  String get email_enterName => 'กรุณากรอกชื่อ';

  @override
  String get email_forgotTitle => 'รีเซ็ตรหัสผ่าน';

  @override
  String get email_forgotMsg => 'กรอกอีเมลของคุณเพื่อรับลิงก์รีเซ็ตรหัสผ่าน';

  @override
  String get email_sendReset => 'ส่ง';

  @override
  String get email_loginWithEmail => 'เข้าสู่ระบบด้วยอีเมล';

  @override
  String get email_confirmSent =>
      'ส่งอีเมลยืนยันบัญชีแล้ว กรุณาตรวจสอบกล่องจดหมายและคลิกลิงก์เพื่อยืนยัน จากนั้นกลับมาเข้าสู่ระบบ';

  @override
  String get email_confirmPasswordHint => 'ยืนยันรหัสผ่าน';

  @override
  String get email_passwordsDoNotMatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get register_childNameHint => 'ชื่อ-นามสกุล';

  @override
  String get register_birthdayHint => 'วว/ดด/ปปปป';

  @override
  String get relation_label => 'ความสัมพันธ์';

  @override
  String get relation_hint => 'เลือกความสัมพันธ์';

  @override
  String get relation_parent => 'พ่อ/แม่';

  @override
  String get relation_grandparentPaternal => 'ปู่/ย่า (ฝ่ายพ่อ)';

  @override
  String get relation_grandparentMaternal => 'ตา/ยาย (ฝ่ายแม่)';

  @override
  String get relation_auntUncle => 'ลุง/ป้า/น้า/อา';

  @override
  String get relation_caregiver => 'คนดูแล';

  @override
  String get relation_nanny => 'พี่เลี้ยง';

  @override
  String get activityhistory_selectDate => 'เลือกวันที่';

  @override
  String activityhistory_times(int count) {
    return '$count ครั้ง';
  }

  @override
  String get activityhistory_noHistory => 'ยังไม่มีประวัติกิจกรรม';

  @override
  String activityhistory_inCategory(String category) {
    return 'ในหมวด $category';
  }

  @override
  String get dailyactivity_playingHistory => 'ประวัติการเล่น';

  @override
  String get dailyactivity_noData => 'ไม่มีข้อมูล';

  @override
  String get dailyactivity_activity => 'กิจกรรม';

  @override
  String get childprofile_language => 'ด้านภาษา';

  @override
  String get childprofile_physical => 'ด้านร่างกาย';

  @override
  String get childprofile_calculation => 'ด้านคำนวณ';

  @override
  String get childprofile_unknownName => 'ไม่ระบุชื่อ';

  @override
  String get childprofile_noHistory => 'ยังไม่มีประวัติกิจกรรม';

  @override
  String get childprofile_startPlaying => 'เริ่มเล่นกิจกรรมเพื่อดูสถิติที่นี่';

  @override
  String get childprofile_totalActivities => 'กิจกรรมทั้งหมด';

  @override
  String get childprofile_times => 'ครั้ง';

  @override
  String get medalredemption_activity => 'กิจกรรม';

  @override
  String get medalredemption_done => 'เสร็จสิ้น';

  @override
  String get medalredemption_points => 'คะแนน';

  @override
  String get playingresult_activity => 'กิจกรรม';

  @override
  String get playingresult_title => 'ผลการเล่น';

  @override
  String playingresult_session(int number) {
    return 'ครั้งที่ $number';
  }

  @override
  String get playingresult_scoreObtained => 'คะแนนที่ได้';

  @override
  String get playingresult_diary => 'บันทึก';

  @override
  String get playingresult_noNotes => 'ไม่มีบันทึก';

  @override
  String get playingresult_image => 'รูปภาพ';

  @override
  String get playingresult_video => 'วิดีโอ';

  @override
  String get playingresult_videoAttached => 'มีวิดีโอแนบ';

  @override
  String get playingresult_timeSpent => 'เวลาที่ใช้';

  @override
  String get playingresult_noImage => 'ไม่มีรูปภาพ';

  @override
  String get playingresult_sentencesSpoken => 'ประโยคที่พูด';

  @override
  String playingresult_sentence(int number) {
    return 'ประโยค $number';
  }

  @override
  String get playingresult_sentenceToSpeak => 'ประโยคที่ต้องพูด:';

  @override
  String get playingresult_whatWasSpoken => 'สิ่งที่พูด:';

  @override
  String get playingresult_noData => '(ไม่มีข้อมูล)';

  @override
  String get playingresult_noSpeechData => 'ไม่มีข้อมูลการพูด';

  @override
  String get playingresult_answerResults => 'ผลการตอบคำถาม';

  @override
  String playingresult_questionLabel(int number) {
    return 'ข้อ $number';
  }

  @override
  String playingresult_questionFallback(int number) {
    return 'คำถามข้อ $number';
  }

  @override
  String get summary_title => 'ตรวจสอบการบันทึกเสียง';

  @override
  String get summary_completeActivity => 'เสร็จสิ้นกิจกรรม';

  @override
  String summary_segmentLabel(int n) {
    return 'ประโยคที่ $n';
  }

  @override
  String summary_pendingAnalysis(int n) {
    return 'กำลังวิเคราะห์อีก $n ประโยค…';
  }

  @override
  String get summary_reRecord => 'อัดเสียงใหม่';

  @override
  String get summary_notRecorded => 'ยังไม่ได้บันทึกเสียง';

  @override
  String get summary_notRecordedShort => '—';

  @override
  String get summary_analyzing => 'กำลังวิเคราะห์…';

  @override
  String get summary_analysisFailed =>
      'วิเคราะห์ไม่สำเร็จ — กดอัดเสียงใหม่เพื่อลองอีกครั้ง';

  @override
  String get summary_youSaid => 'คุณพูดว่า';

  @override
  String get summary_error => 'ข้อผิดพลาด';

  @override
  String get summary_reviewShort => 'ตรวจสอบ';

  @override
  String get summary_stopRecord => 'หยุด';

  @override
  String get profile_gallery => 'เลือกรูปจากคลัง / Gallery';

  @override
  String get profile_google => 'ใช้รูปโปรไฟล์ Google';

  @override
  String get profile_facebook => 'ใช้รูปโปลไฟล์ Facebook';

  @override
  String get math_simulation_scanBtn => 'สแกนคำตอบตรวจการเขียนคำตอบคณิต';

  @override
  String get math_simulation_manualCheckBtn =>
      'ตรวจคำตอบด้วยตนเอง (ไม่ถ่ายภาพ)';

  @override
  String get math_simulation_retakeBtn => 'ถ่ายภาพกระดาษคำตอบใหม่อีกครั้ง';

  @override
  String math_simulation_detectedHeader(int count) {
    return 'ตรวจพบข้อคำตอบทั้งหมด $count ข้อ';
  }

  @override
  String get math_simulation_detectedHint =>
      'กดไอคอนดินสอ เพื่อแก้ไขคำตอบหาก AI แปลงผลคลาดเคลื่อน';

  @override
  String get math_simulation_sectionTitle =>
      'คำตอบที่ระบบอ่านได้ (DETECTED ANSWERS)';

  @override
  String get math_simulation_ocrLabel => 'คำตอบที่อ่านได้: ';

  @override
  String get math_simulation_noData => 'ไม่มีข้อมูล (ตรวจด้วยตนเอง)';

  @override
  String math_simulation_editTitle(int index) {
    return 'แก้ไขคำตอบข้อที่ $index';
  }

  @override
  String get math_simulation_editHint => 'พิมพ์คำตอบคณิตศาสตร์ที่ถูกต้อง...';

  @override
  String math_simulation_questionPrefix(String question) {
    return 'โจทย์: $question';
  }

  @override
  String math_simulation_correctAnswerPrefix(String answer) {
    return 'คำตอบที่ถูกต้อง: $answer';
  }

  @override
  String get math_simulation_prevBtn => 'ข้อก่อนหน้า';

  @override
  String get math_simulation_nextBtn => 'ถัดไป';

  @override
  String get sing_languageBadge => 'ภาษา';

  @override
  String get sing_heroTitle => 'ร้องเพลงให้สนุก\nรับดาวไปเลย!';

  @override
  String get sing_selectOurSongs => 'เลือกเพลงจากเรา';

  @override
  String get sing_readyToPlay => 'เพลงพร้อมเล่น';

  @override
  String get sing_createOwnSong => 'สร้างเพลงเอง';

  @override
  String get sing_wordsOrSentences => 'คำศัพท์ / ประโยค';

  @override
  String get sing_chooseSong => 'เลือกเพลง';

  @override
  String sing_singingChildren(int count) {
    return 'เด็กที่จะร้องเพลงด้วยกัน ($count คน)';
  }

  @override
  String get sing_tapAddChild => 'แตะที่นี่เพื่อเลือกเด็กเพิ่ม';

  @override
  String sing_childrenAdded(int count) {
    return 'เพิ่มเด็กเรียบร้อยแล้ว $count คน';
  }

  @override
  String get sing_startSinging => 'เริ่มร้องเพลง';

  @override
  String get sing_noSongs => 'ยังไม่มีเพลงจากระบบในขณะนี้';

  @override
  String get sing_familySongTitle => 'สร้างเพลงฝึกจำของครอบครัว';

  @override
  String get sing_familySongSubtitle =>
      'ใส่เนื้อหาที่อยากให้เด็กจดจำ แล้วนำไปแต่งเป็นเพลง';

  @override
  String get sing_trainingType => 'อยากฝึกแบบไหน?';

  @override
  String get sing_vocabulary => 'คำศัพท์';

  @override
  String get sing_sentence => 'รูปประโยค';

  @override
  String get sing_vocabularyPrompt => 'คำศัพท์ที่อยากให้เด็กฝึกจำ';

  @override
  String get sing_sentencePrompt => 'รูปประโยคที่อยากให้เด็กฝึกจำ';

  @override
  String get sing_vocabularyHint => 'เช่น apple, banana, orange, happy';

  @override
  String get sing_sentenceHint => 'เช่น I brush my teeth every morning.';

  @override
  String get sing_musicStyle => 'แนวเพลง';

  @override
  String get sing_styleKids => 'เพลงเด็กสนุกสนาน';

  @override
  String get sing_styleDance => 'ป๊อปเต้นตามได้';

  @override
  String get sing_styleWarm => 'เพลงช้าอบอุ่น';

  @override
  String get sing_styleHipHop => 'ฮิปฮอปสำหรับเด็ก';

  @override
  String get sing_uiOnlyNotice =>
      'UI พร้อมแล้ว — ระบบสร้างเพลงจะเชื่อมต่อในขั้นตอนถัดไป';

  @override
  String get sing_createSongButton => 'สร้างเพลงจากเนื้อหานี้';

  @override
  String get sing_showChords => 'แสดงคอร์ดกีต้าร์ผู้ปกครอง';

  @override
  String get sing_hideChords => 'ซ่อนคอร์ดกีต้าร์';

  @override
  String get sing_chordsShown => 'เปิดโหมดคอร์ดกีต้าร์สำหรับผู้ปกครองแล้ว';

  @override
  String get sing_chordsHidden => 'ซ่อนคอร์ดกีต้าร์แล้ว';

  @override
  String get sing_videoSyncHint => 'วิดีโอเต้นจะเล่นพร้อมเพลง';

  @override
  String get sing_hideVideo => 'ซ่อนวิดีโอเต้น';

  @override
  String get sing_showVideo => 'แสดงวิดีโอเต้น';

  @override
  String get sing_retryVideo => 'ลองโหลดวิดีโออีกครั้ง';

  @override
  String get sing_evidenceAttached => 'แนบไฟล์หลักฐานแล้ว';

  @override
  String get sing_captureEvidence => 'ถ่ายรูปหรืออัดคลิปวิดีโอหลักฐาน';

  @override
  String get sing_attached => 'แนบแล้ว';

  @override
  String get sing_recordVideo => 'อัดคลิปวิดีโอ';

  @override
  String get sing_takePhoto => 'ถ่ายรูปภาพ';

  @override
  String get sing_openVideo => 'เปิดคลิปวิดีโอ';

  @override
  String get sing_songVocabulary => 'คำศัพท์น่ารู้ประจำเพลง:';

  @override
  String sing_pronunciation(String value) {
    return 'คำอ่าน: $value';
  }

  @override
  String sing_translation(String value) {
    return 'คำแปล: $value';
  }

  @override
  String get sing_cameraPreparing => 'กำลังเตรียมกล้องในแอป...';

  @override
  String get sing_cameraRecording => 'กำลังอัดวิดีโอพร้อมเพลง...';

  @override
  String get sing_hubSubtitle =>
      'ฟังเพลงสองภาษา พร้อมโหมดคอร์ดกีต้าร์สำหรับผู้ปกครอง';

  @override
  String get sing_evaluationTitle => 'ให้คะแนนร้องเพลง Sing Together';

  @override
  String sing_selectMediaSource(String media) {
    return 'เลือกแหล่งที่มา: $media';
  }

  @override
  String get sing_childFallback => 'น้อง';

  @override
  String sing_saveScoreError(String error) {
    return 'เกิดข้อผิดพลาดในการบันทึกคะแนน: $error';
  }

  @override
  String sing_scoreChild(String name) {
    return 'ให้คะแนน $name';
  }

  @override
  String get sing_scoreLabel => 'คะแนน (0–100)';

  @override
  String sing_duration(int minutes, int seconds) {
    return 'เวลาที่ใช้ร้อง: $minutes นาที $seconds วินาที';
  }

  @override
  String get sing_imageVideoEvidence => 'หลักฐานรูปภาพ / วิดีโอ';

  @override
  String get sing_change => 'เปลี่ยน';

  @override
  String get sing_watchVideo => 'ดูคลิปวิดีโอ 🎥';

  @override
  String sing_evaluateChildren(int count) {
    return 'ประเมินคะแนนเด็ก ($count คน)';
  }

  @override
  String get sing_notesTitle => 'บันทึกข้อคิดเห็นเพิ่มเติม';

  @override
  String get sing_notesHint =>
      'เช่น ร้องเสียงดังฟังชัด ออกเสียงคำศัพท์ได้ถูกต้อง...';

  @override
  String get sing_savingScore => 'กำลังบันทึกคะแนน...';

  @override
  String get sing_saveScore => 'บันทึกคะแนนการร้องเพลง';

  @override
  String get common_loading => 'กำลังโหลด...';

  @override
  String get common_pleaseWait => 'กรุณารอสักครู่';

  @override
  String get common_add => 'เพิ่ม';

  @override
  String common_attachmentError(String error) {
    return 'เกิดข้อผิดพลาดในการแนบสื่อ: $error';
  }

  @override
  String languageList_loadError(String error) {
    return 'ไม่สามารถโหลดกิจกรรมได้: $error';
  }

  @override
  String get languageList_empty => 'ยังไม่มีกิจกรรมในหมวดนี้';

  @override
  String get dynamic_listening => 'กำลังฟัง...';

  @override
  String get dynamic_holdToSpeak => 'กดค้างเพื่อพูด';

  @override
  String get dynamic_greatJob => 'เก่งมาก!';

  @override
  String get dynamic_niceTry => 'พยายามอีกนิด!';

  @override
  String get disclaimer_title => 'ข้อตกลงในการใช้ซอฟต์แวร์';

  @override
  String get disclaimer_acceptCheck =>
      'ฉันได้อ่าน เข้าใจ และยอมรับข้อตกลงข้างต้น';

  @override
  String get disclaimer_acceptButton => 'ยอมรับและดำเนินการต่อ';

  @override
  String get disclaimer_intro =>
      'ซอฟต์แวร์ Skill Wallet Kizuna พัฒนาขึ้นภายใต้การแข่งขันพัฒนาโปรแกรมคอมพิวเตอร์แห่งประเทศไทย ครั้งที่ 28 (NSC 2026) เพื่อส่งเสริมการเรียนรู้และทักษะของเด็กผ่านกิจกรรมในครอบครัว';

  @override
  String get disclaimer_developers => 'ผู้พัฒนา';

  @override
  String get disclaimer_advisor => 'อาจารย์ที่ปรึกษา';

  @override
  String get disclaimer_terms => 'ข้อตกลงการใช้งาน';

  @override
  String get disclaimer_license =>
      'ทรัพย์สินทางปัญญาของซอฟต์แวร์นี้เป็นของผู้พัฒนา และอนุญาตให้ สวทช. เผยแพร่ซอฟต์แวร์ในลักษณะตามสภาพ เพื่อใช้ชั่วคราว แบบไม่ผูกขาด สำหรับการศึกษาหรือการใช้งานส่วนบุคคลที่ไม่ใช่เชิงพาณิชย์โดยไม่มีค่าตอบแทน';

  @override
  String get disclaimer_liability =>
      'สวทช. และผู้พัฒนาไม่รับผิดชอบต่อความสูญเสีย ความเสียหาย ข้อผิดพลาด ประสิทธิภาพ หรือผลจากการใช้งาน ผู้ใช้มีหน้าที่ดูแลและจัดการการใช้งานด้วยตนเอง';

  @override
  String get daily_singTogether => 'Sing Together';

  @override
  String get createActivity_physicalTitle => 'สร้างกิจกรรมด้านร่างกาย';

  @override
  String get createActivity_calculateTitle => 'สร้างกิจกรรมด้านคำนวณ';

  @override
  String get createActivity_mathTitle => 'สร้างกิจกรรมโจทย์คณิตศาสตร์';

  @override
  String get createActivity_voiceTitle => 'สร้างกิจกรรม Voice Quest';

  @override
  String get createActivity_spaceTitle => 'สร้างกิจกรรม Space Adventure';

  @override
  String get createActivity_maxScoreRequired => 'กรุณากรอกคะแนนเต็ม';

  @override
  String get createActivity_timeRequired => 'กรุณากรอกระยะเวลาที่กำหนด';

  @override
  String get createActivity_itemScoreRequired => 'กรุณากรอกคะแนนต่อชิ้น';

  @override
  String get createActivity_wordCategory => 'หมวดหมู่คำศัพท์';

  @override
  String get createActivity_timeLimit => 'ระยะเวลาที่กำหนด (วินาที)';

  @override
  String get createActivity_scorePerItem => 'คะแนนต่อวัตถุที่สแกนเจอ';

  @override
  String get wordCategory_animals => '🦁 สัตว์';

  @override
  String get wordCategory_food => '🍎 อาหาร';

  @override
  String get wordCategory_vehicles => '🚀 ยานพาหนะ';

  @override
  String get wordCategory_nature => '🌈 ธรรมชาติ';

  @override
  String get wordCategory_bedroom => '🛏️ ห้องนอน';

  @override
  String get wordCategory_school => '🎒 โรงเรียน';

  @override
  String get disclaimer_developer1 => 'นายกนก กลิ่นสุวรรณ์';

  @override
  String get disclaimer_developer2 => 'นายพจนัณท์ โอสถานันท์';

  @override
  String get disclaimer_developer3 => 'นายนวพล กิตินันท์ประกร';

  @override
  String get disclaimer_advisorName =>
      'ผู้ช่วยศาสตราจารย์ ดร.สุวัจชัย กมลสันติโรจน์';

  @override
  String math_scanCorrect(int index, String text) {
    return 'ตรวจข้อ $index: อ่านได้ “$text” (ถูกต้อง ✓)';
  }

  @override
  String math_scanIncorrect(int index, String text) {
    return 'ตรวจข้อ $index: อ่านได้ “$text” (ไม่ตรงกับเฉลย)';
  }

  @override
  String get math_noRecognition => 'ไม่พบผลการอ่านจากภาพ';

  @override
  String math_scanQuestionError(int index, String error) {
    return 'เกิดข้อผิดพลาดในการสแกนข้อ $index: $error';
  }

  @override
  String get math_noAnswerFound => 'ไม่พบคำตอบ';

  @override
  String get math_invalidServerResponse =>
      'เซิร์ฟเวอร์ส่งข้อมูลกลับในรูปแบบที่ไม่ถูกต้อง';

  @override
  String math_scanError(String error) {
    return 'เกิดข้อผิดพลาดในการสแกน: $error';
  }

  @override
  String math_submitError(String error) {
    return 'ส่งคำตอบล้มเหลว: $error';
  }

  @override
  String get math_scanResultTitle => 'ผลการสแกนการตรวจคำตอบ';

  @override
  String get math_activityTitle => 'กิจกรรมคณิตศาสตร์ตามสถานการณ์จำลอง';

  @override
  String get math_exitTvMode => 'ออกจากโหมด Smart TV';

  @override
  String math_questionImage(int index) {
    return 'ภาพข้อที่ $index';
  }

  @override
  String get math_swipeNextImage => 'เลื่อนไปดูรูปข้อถัดไป';

  @override
  String get math_end => 'จบ';

  @override
  String get math_noImage => 'ยังไม่มีรูปสำหรับข้อนี้';

  @override
  String get math_activityDetails => 'รายละเอียดกิจกรรม';

  @override
  String get math_defaultDescription =>
      'ฝึกคิดวิเคราะห์และแก้โจทย์คณิตศาสตร์ผ่านภาพสถานการณ์จริง บันทึกคำตอบลงในกระดาษก่อนกดสแกน';

  @override
  String get math_paperInstruction =>
      'เตรียมกระดาษและดินสอเขียนคำตอบ ตัวเลขคำตอบควรเขียนให้ชัดเพื่อสแกนตรวจ';

  @override
  String math_questionProgress(int current, int total) {
    return 'ข้อที่ $current จาก $total';
  }

  @override
  String get math_proposition => 'สถานการณ์ปัญหาวิเคราะห์';

  @override
  String get math_reviewAll => 'ตรวจสรุปผลทั้งหมด';

  @override
  String math_cameraCheck(int index) {
    return 'ตรวจคำตอบด้วยกล้อง (ข้อที่ $index)';
  }

  @override
  String get math_readingHandwriting => 'กำลังอ่านลายมือจากภาพถ่าย...';

  @override
  String math_readCorrect(String text) {
    return 'อ่านได้ “$text” (ถูกต้อง ✓)';
  }

  @override
  String math_readIncorrect(String text) {
    return 'อ่านได้ “$text” (ไม่ตรงเฉลย)';
  }

  @override
  String get math_takePhotoHint => 'ถ่ายรูปลายมือเฉพาะข้อนี้เพื่อตรวจทันที';

  @override
  String get math_thisQuestionImage => 'ภาพข้อนี้';

  @override
  String get math_readingAi => 'กำลังอ่านลายมือด้วย AI...';

  @override
  String get math_retakeQuestion => 'ถ่ายรูปตรวจข้อนี้ใหม่';

  @override
  String get math_scanQuestion => 'ถ่ายรูป / สแกนตรวจข้อนี้';

  @override
  String get math_editNumber => 'แก้ไขตัวเลข';

  @override
  String get math_readingAll => 'กำลังอ่านคำตอบจากภาพ';

  @override
  String get math_waitFindingNumbers =>
      'กรุณารอสักครู่ ระบบกำลังค้นหาตัวเลขทั้งหมด';

  @override
  String get math_checkAll => 'ตรวจคำตอบทั้งหมด';

  @override
  String get math_reviewBeforeFinish => 'ตรวจสอบและแก้ไขผลก่อนกดเสร็จสิ้น';

  @override
  String get math_answerList => 'รายการคำตอบ';

  @override
  String math_solutionValue(String value) {
    return 'เฉลย: $value';
  }

  @override
  String get math_noAnswerDetected => 'ยังไม่พบคำตอบ';

  @override
  String get math_rescan => 'สแกนใหม่';

  @override
  String get math_wellDone => 'เก่งมากเลย!';

  @override
  String get math_rewardSaved => 'บันทึกคะแนนและแต้มรางวัลเรียบร้อยแล้ว';

  @override
  String history_redeemed(String name) {
    return 'แลก $name';
  }

  @override
  String get history_rewardFallback => 'ของรางวัล';

  @override
  String spaceScan_pickerError(String error) {
    return 'เปิดตัวเลือกรูปภาพไม่ได้: $error';
  }

  @override
  String get spaceScan_failed => 'สแกนไม่สำเร็จ';

  @override
  String spaceScan_reason(String reason) {
    return 'สาเหตุ: $reason';
  }

  @override
  String get spaceScan_selectSource => 'เลือกแหล่งรูปภาพ';

  @override
  String get spaceScan_scanFirst =>
      'กรุณาสแกนห้องเพื่อค้นหาสิ่งของก่อนเริ่มผจญภัย';

  @override
  String get spaceScan_deleteItem => 'ลบสิ่งของหรือไม่?';

  @override
  String spaceScan_deleteConfirm(String item) {
    return 'ต้องการนำ “$item” ออกจากภารกิจนี้หรือไม่?';
  }

  @override
  String get spaceScan_delete => 'ลบ';

  @override
  String get spaceScan_noTargets => 'พื้นที่นี้ยังไม่มีสิ่งของเป้าหมาย';

  @override
  String get spaceScan_choosePreset => 'เลือกพื้นที่สำเร็จรูป';

  @override
  String get spaceScan_presetDescription =>
      'ใช้รายการสิ่งของที่จัดการไว้ใน Space Adventure CMS';

  @override
  String get spaceScan_noPresets =>
      'ยังไม่มีพื้นที่สำเร็จรูป\nกรุณาเพิ่มพื้นที่ใน Space Adventure CMS';

  @override
  String get spaceScan_phase => 'ขั้นที่ 1: สแกนห้อง';

  @override
  String get spaceScan_intro => 'ถ่ายรูปห้องเพื่อค้นหาสิ่งของสำหรับภารกิจ';

  @override
  String get spaceScan_usePreset => 'ใช้รายการพร้อมเล่น';

  @override
  String get spaceScan_cmsItems => 'รายการจาก CMS';

  @override
  String get spaceScan_scanRoom => 'สแกนห้อง';

  @override
  String get spaceScan_findItems => 'ค้นหาของในรูป';

  @override
  String get spaceScan_tapPhoto => 'แตะปุ่มด้านล่างเพื่อถ่ายรูป';

  @override
  String get spaceScan_scanning => 'กำลังค้นหาสิ่งของ...';

  @override
  String get spaceScan_itemsDetected => 'สิ่งของที่พบ:';

  @override
  String get spaceScan_startQuest => 'เริ่มภารกิจ';

  @override
  String get spaceScan_rescan => 'สแกนใหม่';

  @override
  String get dynamic_languageTitle => 'ภาษา';

  @override
  String get dynamic_tagline => 'พูดคำศัพท์\nคว้าดาวให้ได้!';

  @override
  String get dynamic_chooseCategory => 'เลือกหมวดคำศัพท์';

  @override
  String get dynamic_todayGoal => 'เป้าหมายวันนี้';

  @override
  String get dynamic_startQuest => 'เริ่มภารกิจ';

  @override
  String get dynamic_exitTvMode => 'ออกจากโหมดทีวี';

  @override
  String get dynamic_tvMode => 'โหมดทีวี';

  @override
  String get dynamic_listen => 'ฟังเสียง';

  @override
  String dynamic_progress(int current, int total) {
    return 'คำที่ $current จาก $total';
  }

  @override
  String get dynamic_sayWord => 'พูดคำนี้:';

  @override
  String dynamic_meaning(String meaning) {
    return 'ความหมาย: $meaning';
  }

  @override
  String dynamic_listenWord(String word) {
    return 'ฟังเสียง: $word';
  }

  @override
  String get dynamic_evaluating => 'กำลังประเมินเสียงของคุณ...';

  @override
  String get dynamic_speakInstruction =>
      'กดค้างไว้ขณะพูด และปล่อยเมื่อพูดเสร็จ';

  @override
  String get dynamic_youSaid => 'คุณพูดว่า:';

  @override
  String dynamic_targetWord(String word) {
    return 'คำเป้าหมาย: $word';
  }

  @override
  String get dynamic_listenVoice => 'ฟังเสียงของคุณ';

  @override
  String get dynamic_speakAgain => 'พูดอีกครั้ง';

  @override
  String get dynamic_questComplete => 'ทำภารกิจสำเร็จ!';

  @override
  String get dynamic_totalScore => 'คะแนนรวม';

  @override
  String get dynamic_playRecordingError => 'เล่นเสียงที่บันทึกไว้ไม่ได้';

  @override
  String get dynamic_micPermission =>
      'ไม่ได้รับอนุญาตให้ใช้ไมโครโฟน กรุณาเปิดสิทธิ์ไมโครโฟน';

  @override
  String get dynamic_noSpeech =>
      'ไม่ได้ยินเสียงพูด กรุณากดไมค์ค้างไว้และพูดให้ชัดเจน';

  @override
  String get spaceQuest_timeout => 'หมดเวลาภารกิจอวกาศแล้ว!';

  @override
  String get spaceQuest_verifyError => 'ตรวจสอบไม่สำเร็จ กรุณาลองอีกครั้ง';

  @override
  String get spaceQuest_objectHunter => 'นักล่าสิ่งของ';

  @override
  String spaceQuest_score(int score) {
    return 'คะแนน: $score';
  }

  @override
  String spaceQuest_mission(int current, int total) {
    return 'ภารกิจอวกาศ $current/$total';
  }

  @override
  String get spaceQuest_capture => 'ถ่ายรูปสิ่งของ';

  @override
  String get spaceQuest_findTake => 'ค้นหาและถ่ายรูปสิ่งของเป้าหมาย';

  @override
  String get spaceQuest_verify => 'ตรวจสอบรูป';

  @override
  String get spaceQuest_selectChild => 'กรุณาเลือกโปรไฟล์เด็กก่อนบันทึกคะแนน';

  @override
  String get spaceQuest_shareWeb =>
      'การแชร์รองรับบนมือถือ ส่วนเว็บไซต์ให้คลิกขวาที่รูปเพื่อบันทึก';

  @override
  String get spaceQuest_sharePhoto => 'แชร์รูป';

  @override
  String get spaceQuest_recapture => 'ถ่ายใหม่';

  @override
  String get spaceQuest_complete => 'ทำภารกิจสำเร็จ!';

  @override
  String get spaceQuest_totalScore => 'คะแนนรวม';

  @override
  String get addChild_title => 'เพิ่มนักผจญภัยตัวน้อย';

  @override
  String get addChild_subtitle =>
      'เพิ่มข้อมูลเด็กและเริ่มสร้างนิสัยที่ดีไปด้วยกัน';

  @override
  String get addChild_name => 'ชื่อเด็ก';

  @override
  String get addChild_nameHint => 'เช่น ปกป้อง';

  @override
  String get addChild_birthDate => 'วันเกิด';

  @override
  String get addChild_relationship => 'ความสัมพันธ์';

  @override
  String get addChild_mother => 'แม่';

  @override
  String get addChild_button => 'เพิ่มเด็ก';

  @override
  String get home_welcomeBack => 'ยินดีต้อนรับกลับ';

  @override
  String get home_whosHere => 'วันนี้ใครอยู่ด้วย?';

  @override
  String get home_add => 'เพิ่ม';

  @override
  String get home_rewardPoints => 'แต้มรางวัล';

  @override
  String get home_redeem => 'แลกรางวัล';

  @override
  String get home_activities => 'กิจกรรม';

  @override
  String get home_newBadge => 'ใหม่';

  @override
  String get home_spaceDescription => 'สแกนห้องและค้นหาสิ่งของที่ซ่อนอยู่!';

  @override
  String get common_continueGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get common_continueFacebook => 'ดำเนินการต่อด้วย Facebook';

  @override
  String get common_home => 'หน้าหลัก';

  @override
  String get common_disclaimer => 'ข้อกำหนดการใช้งาน';

  @override
  String get common_login => 'เข้าสู่ระบบ';

  @override
  String get common_copiedShareText => 'คัดลอกข้อความสำหรับแชร์แล้ว';

  @override
  String get common_copyShareText => 'คัดลอกข้อความสำหรับแชร์';

  @override
  String get createActivity_choosePrompt => 'เลือกกิจกรรมที่ต้องการสร้าง';

  @override
  String get sing_difficultyEasy => 'ง่าย';

  @override
  String get sing_highScore => 'คะแนนสูงสุด: 100';

  @override
  String get sing_durationMinutes => '10 นาที';

  @override
  String get dynamic_todayCategory => 'หมวดคำศัพท์วันนี้';

  @override
  String get dynamic_speaking => 'กำลังพูด';

  @override
  String get dynamic_silence => '(ไม่มีเสียง)';

  @override
  String dynamic_scoreEarned(int score) {
    return '+$score คะแนน';
  }

  @override
  String get dynamic_perfect => 'ยอดเยี่ยม! 🏆';

  @override
  String dynamic_voiceMatch(int percent) {
    return 'เสียงตรงกัน $percent% 🎙';
  }

  @override
  String get dynamic_nextWord => 'คำถัดไป';

  @override
  String spaceQuest_findItem(String item) {
    return 'ค้นหา: $item';
  }

  @override
  String get spaceQuest_timeoutReason => 'หมดเวลาก่อนตรวจสอบรูป';

  @override
  String get spaceQuest_scanResults => 'ผลการสแกน';

  @override
  String get spaceQuest_correctMatch => 'รูปตรงกับเป้าหมาย';

  @override
  String get spaceQuest_mismatch => 'รูปยังไม่ตรงกับเป้าหมาย';

  @override
  String spaceQuest_verifiedTarget(String item) {
    return 'Vision AI ตรวจพบเป้าหมาย: $item';
  }

  @override
  String spaceQuest_notMatched(String item) {
    return 'รูปนี้ยังไม่ตรงกับ $item กรุณาลองอีกครั้ง';
  }

  @override
  String spaceQuest_scored(int points, int total) {
    return 'ได้เพิ่ม $points คะแนน คะแนนรวมปัจจุบัน $total';
  }

  @override
  String spaceQuest_currentTotal(int total) {
    return 'คะแนนรวมปัจจุบัน $total คะแนน';
  }

  @override
  String get spaceQuest_saving => 'กำลังบันทึกคะแนน...';

  @override
  String get spaceQuest_next => 'ภารกิจถัดไป';

  @override
  String get home_parentFallback => 'ผู้ปกครอง';

  @override
  String get welcome_intro =>
      'มาเริ่มกันเลย!\nถ้าเคยใช้งานแล้ว ยินดีต้อนรับกลับ\nหากเพิ่งมาใหม่ มาร่วมเรียนรู้และเติบโตไปด้วยกัน';

  @override
  String get common_shareDownloadImage => 'แชร์ / ดาวน์โหลดรูป';

  @override
  String itemintro_noSegments(String name) {
    return 'ข้อผิดพลาด: ไม่พบช่วงกิจกรรมสำหรับ $name';
  }

  @override
  String get record_streamUnsupported =>
      'เบราว์เซอร์นี้ไม่รองรับการบันทึกเสียงแบบสตรีม';
}
