import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th')
  ];

  /// No description provided for @welcome_playBtn.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get welcome_playBtn;

  /// No description provided for @welcome_signUpBtn.
  ///
  /// In en, this message translates to:
  /// **'SIGN-UP'**
  String get welcome_signUpBtn;

  /// No description provided for @welcome_signInBtn.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get welcome_signInBtn;

  /// No description provided for @home_categoryBtn.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get home_categoryBtn;

  /// No description provided for @home_physicalBtn.
  ///
  /// In en, this message translates to:
  /// **'PHYSICAL'**
  String get home_physicalBtn;

  /// No description provided for @home_languageBtn.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get home_languageBtn;

  /// No description provided for @home_calculationBtn.
  ///
  /// In en, this message translates to:
  /// **'CALCULATION'**
  String get home_calculationBtn;

  /// No description provided for @home_cannotBtn.
  ///
  /// In en, this message translates to:
  /// **'Cannot load popular activities'**
  String get home_cannotBtn;

  /// No description provided for @home_nonewBtn.
  ///
  /// In en, this message translates to:
  /// **'No new activities available'**
  String get home_nonewBtn;

  /// No description provided for @home_noChildrenMsg.
  ///
  /// In en, this message translates to:
  /// **'No children added yet.\nPlease add a child to start viewing activities.'**
  String get home_noChildrenMsg;

  /// No description provided for @home_switchChild.
  ///
  /// In en, this message translates to:
  /// **'Switch Child'**
  String get home_switchChild;

  /// No description provided for @draft_bannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity in progress'**
  String get draft_bannerTitle;

  /// No description provided for @draft_bannerResume.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get draft_bannerResume;

  /// No description provided for @draft_bannerDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get draft_bannerDiscard;

  /// No description provided for @draft_discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard progress?'**
  String get draft_discardTitle;

  /// No description provided for @draft_discardMsg.
  ///
  /// In en, this message translates to:
  /// **'Your saved progress for this activity will be deleted.'**
  String get draft_discardMsg;

  /// No description provided for @draft_leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave activity?'**
  String get draft_leaveTitle;

  /// No description provided for @draft_leaveMsg.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be saved. You can continue later from the home screen.'**
  String get draft_leaveMsg;

  /// No description provided for @draft_leaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save & Leave'**
  String get draft_leaveBtn;

  /// No description provided for @draft_conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Active saved progress'**
  String get draft_conflictTitle;

  /// No description provided for @draft_conflictMsg.
  ///
  /// In en, this message translates to:
  /// **'You have saved progress for \"{name}\". Starting a new activity will discard it, or you can cancel and resume.'**
  String draft_conflictMsg(String name);

  /// No description provided for @draft_conflictPlay.
  ///
  /// In en, this message translates to:
  /// **'Start New'**
  String get draft_conflictPlay;

  /// No description provided for @common_discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get common_discardChanges;

  /// No description provided for @common_discardMsg.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get common_discardMsg;

  /// No description provided for @common_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get common_discard;

  /// No description provided for @common_keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get common_keepEditing;

  /// No description provided for @home_popularactivityBtn.
  ///
  /// In en, this message translates to:
  /// **'POPULAR ACTIVITIES'**
  String get home_popularactivityBtn;

  /// No description provided for @home_newactivityBtn.
  ///
  /// In en, this message translates to:
  /// **'NEW ACTIVITIES'**
  String get home_newactivityBtn;

  /// No description provided for @home_viewallBtn.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get home_viewallBtn;

  /// No description provided for @home_searchBtn.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get home_searchBtn;

  /// No description provided for @home_bannerLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE TRAINING'**
  String get home_bannerLanguage;

  /// No description provided for @home_bannerCalculate.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE'**
  String get home_bannerCalculate;

  /// No description provided for @home_bannerProblems.
  ///
  /// In en, this message translates to:
  /// **'PROBLEMS SOLVE'**
  String get home_bannerProblems;

  /// No description provided for @home_filterTitle.
  ///
  /// In en, this message translates to:
  /// **'FILTER ACTIVITIES'**
  String get home_filterTitle;

  /// No description provided for @home_filterCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get home_filterCategory;

  /// No description provided for @home_filterLevel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL'**
  String get home_filterLevel;

  /// No description provided for @home_filterAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get home_filterAll;

  /// No description provided for @home_filterEasy.
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get home_filterEasy;

  /// No description provided for @home_filterMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get home_filterMedium;

  /// No description provided for @home_filterHard.
  ///
  /// In en, this message translates to:
  /// **'HARD'**
  String get home_filterHard;

  /// No description provided for @home_suggested.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTED'**
  String get home_suggested;

  /// No description provided for @parentprofile_postBtn.
  ///
  /// In en, this message translates to:
  /// **'POST'**
  String get parentprofile_postBtn;

  /// No description provided for @register_backBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get register_backBtn;

  /// No description provided for @register_signuptoBtn.
  ///
  /// In en, this message translates to:
  /// **'SIGN-UP TO'**
  String get register_signuptoBtn;

  /// No description provided for @register_facebookBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH FACEBOOK'**
  String get register_facebookBtn;

  /// No description provided for @register_googleBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH GOOGLE'**
  String get register_googleBtn;

  /// No description provided for @register_nextBtn.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get register_nextBtn;

  /// No description provided for @register_registerBtn.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get register_registerBtn;

  /// No description provided for @register_additionalBtn.
  ///
  /// In en, this message translates to:
  /// **'ADDITIONAL INFORMATION'**
  String get register_additionalBtn;

  /// No description provided for @register_namesurnamechildBtn.
  ///
  /// In en, this message translates to:
  /// **'NAME & SURNAME (CHILDREN) {index}'**
  String register_namesurnamechildBtn(Object index);

  /// No description provided for @register_birthdayBtn.
  ///
  /// In en, this message translates to:
  /// **'BIRTHDAY : DD/MM/YYYY'**
  String get register_birthdayBtn;

  /// No description provided for @register_okBtn.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get register_okBtn;

  /// No description provided for @register_pls.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all the information in the list. '**
  String get register_pls;

  /// No description provided for @register_finish.
  ///
  /// In en, this message translates to:
  /// **'Successfully registered!'**
  String get register_finish;

  /// No description provided for @register_relation.
  ///
  /// In en, this message translates to:
  /// **'RELATION'**
  String get register_relation;

  /// No description provided for @register_pickbirthday.
  ///
  /// In en, this message translates to:
  /// **'Choose birthday'**
  String get register_pickbirthday;

  /// No description provided for @register_Anerroroccurredplstry.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get register_Anerroroccurredplstry;

  /// No description provided for @register_Anerroroccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {index}'**
  String register_Anerroroccurred(Object index);

  /// No description provided for @register_sus.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Added {index} child.'**
  String register_sus(Object index);

  /// No description provided for @register_submitterror.
  ///
  /// In en, this message translates to:
  /// **'Submit error: {index}'**
  String register_submitterror(Object index);

  /// No description provided for @register_requiredinformation.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all the required information (name, date of birth, relationship) in the list. {index}'**
  String register_requiredinformation(Object index);

  /// No description provided for @login_backBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get login_backBtn;

  /// No description provided for @login_facebookBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH FACEBOOK'**
  String get login_facebookBtn;

  /// No description provided for @login_googleBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH GOOGLE'**
  String get login_googleBtn;

  /// No description provided for @login_loading.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get login_loading;

  /// No description provided for @login_noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account found. Please register first.'**
  String get login_noAccount;

  /// No description provided for @login_goToRegister.
  ///
  /// In en, this message translates to:
  /// **'GO TO REGISTER'**
  String get login_goToRegister;

  /// No description provided for @register_loading.
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get register_loading;

  /// No description provided for @register_alreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This account is already registered. Please login instead.'**
  String get register_alreadyExists;

  /// No description provided for @register_goToLogin.
  ///
  /// In en, this message translates to:
  /// **'GO TO LOGIN'**
  String get register_goToLogin;

  /// No description provided for @auth_termsAgree.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the'**
  String get auth_termsAgree;

  /// No description provided for @auth_termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get auth_termsOfService;

  /// No description provided for @auth_privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get auth_privacyPolicy;

  /// No description provided for @auth_and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get auth_and;

  /// No description provided for @auth_pleaseAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Service and Privacy Policy first.'**
  String get auth_pleaseAgreeTerms;

  /// No description provided for @auth_loading.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get auth_loading;

  /// No description provided for @auth_tosDialogMsg.
  ///
  /// In en, this message translates to:
  /// **'To ensure things are in your best interests, please review the Terms of Service and then choose to enter.'**
  String get auth_tosDialogMsg;

  /// No description provided for @auth_readTos.
  ///
  /// In en, this message translates to:
  /// **'Read TOS'**
  String get auth_readTos;

  /// No description provided for @auth_enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get auth_enter;

  /// No description provided for @setting_backBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get setting_backBtn;

  /// No description provided for @setting_settingBtn.
  ///
  /// In en, this message translates to:
  /// **'SETTING'**
  String get setting_settingBtn;

  /// No description provided for @setting_personalBtn.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFORMATION'**
  String get setting_personalBtn;

  /// No description provided for @setting_generalBtn.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get setting_generalBtn;

  /// No description provided for @setting_profileBtn.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get setting_profileBtn;

  /// No description provided for @setting_childBtn.
  ///
  /// In en, this message translates to:
  /// **'CHILD'**
  String get setting_childBtn;

  /// No description provided for @setting_notificationBtn.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get setting_notificationBtn;

  /// No description provided for @setting_thaiBtn.
  ///
  /// In en, this message translates to:
  /// **'THAI'**
  String get setting_thaiBtn;

  /// No description provided for @setting_englishBtn.
  ///
  /// In en, this message translates to:
  /// **'ENGLISH'**
  String get setting_englishBtn;

  /// No description provided for @setting_logoutBtn.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get setting_logoutBtn;

  /// No description provided for @setting_logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out?'**
  String get setting_logoutTitle;

  /// No description provided for @setting_logoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get setting_logoutMsg;

  /// No description provided for @setting_logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get setting_logoutConfirm;

  /// No description provided for @setting_deleteAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get setting_deleteAccountBtn;

  /// No description provided for @setting_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get setting_deleteTitle;

  /// No description provided for @setting_deleteMsg.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all children data. Your data will be removed within 30 days. This action cannot be undone.'**
  String get setting_deleteMsg;

  /// No description provided for @setting_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get setting_deleteConfirm;

  /// No description provided for @setting_deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get setting_deleteSuccess;

  /// No description provided for @setting_deleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again.'**
  String get setting_deleteError;

  /// No description provided for @namesetting_changenameBtn.
  ///
  /// In en, this message translates to:
  /// **'CHANGE NAME'**
  String get namesetting_changenameBtn;

  /// No description provided for @namesetting_enternewnameBtn.
  ///
  /// In en, this message translates to:
  /// **'ENTER NEW NAME'**
  String get namesetting_enternewnameBtn;

  /// No description provided for @namesetting_hint.
  ///
  /// In en, this message translates to:
  /// **'Type your name...'**
  String get namesetting_hint;

  /// No description provided for @namesetting_saveBtn.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get namesetting_saveBtn;

  /// No description provided for @profilesetting_nameBtn.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get profilesetting_nameBtn;

  /// No description provided for @profilesetting_deleteaccoutBtn.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get profilesetting_deleteaccoutBtn;

  /// No description provided for @profileSet_deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT?'**
  String get profileSet_deleteDialogTitle;

  /// No description provided for @profilesetting_areusureBtn.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get profilesetting_areusureBtn;

  /// No description provided for @profilesetting_cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get profilesetting_cancelBtn;

  /// No description provided for @profilesetting_deleteBtn.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get profilesetting_deleteBtn;

  /// No description provided for @childprofile_mathGame.
  ///
  /// In en, this message translates to:
  /// **'MATH GAME'**
  String get childprofile_mathGame;

  /// No description provided for @childprofile_workoutGame.
  ///
  /// In en, this message translates to:
  /// **'WORK OUT GAME'**
  String get childprofile_workoutGame;

  /// No description provided for @childsetting_childsettingBtn.
  ///
  /// In en, this message translates to:
  /// **'CHILD SETTING'**
  String get childsetting_childsettingBtn;

  /// No description provided for @childsetting_scoreBtn.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get childsetting_scoreBtn;

  /// No description provided for @childsetting_viewprofileBtn.
  ///
  /// In en, this message translates to:
  /// **'VIEW PROFILE'**
  String get childsetting_viewprofileBtn;

  /// No description provided for @childsetting_manageBtn.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get childsetting_manageBtn;

  /// No description provided for @childgallery_title.
  ///
  /// In en, this message translates to:
  /// **'MY GALLERY'**
  String get childgallery_title;

  /// No description provided for @childgallery_empty.
  ///
  /// In en, this message translates to:
  /// **'NO POSTS YET'**
  String get childgallery_empty;

  /// No description provided for @history_timesSuffix.
  ///
  /// In en, this message translates to:
  /// **'TIMES'**
  String get history_timesSuffix;

  /// No description provided for @result_title.
  ///
  /// In en, this message translates to:
  /// **'PLAYING RESULT'**
  String get result_title;

  /// No description provided for @result_timeUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'TIME USED'**
  String get result_timeUsedTitle;

  /// No description provided for @redemption_playBtn.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get redemption_playBtn;

  /// No description provided for @redemption_rewardIceCream.
  ///
  /// In en, this message translates to:
  /// **'ICE CREAM'**
  String get redemption_rewardIceCream;

  /// No description provided for @redemption_rewardPlaytime.
  ///
  /// In en, this message translates to:
  /// **'1 HR PLAYTIME'**
  String get redemption_rewardPlaytime;

  /// No description provided for @redemption_rewardToy.
  ///
  /// In en, this message translates to:
  /// **'NEW TOY'**
  String get redemption_rewardToy;

  /// No description provided for @redemption_rewardStickers.
  ///
  /// In en, this message translates to:
  /// **'STICKERS'**
  String get redemption_rewardStickers;

  /// No description provided for @redemption_historyPlayedDefault.
  ///
  /// In en, this message translates to:
  /// **'Played Ping Pong'**
  String get redemption_historyPlayedDefault;

  /// No description provided for @redemption_historyRedeemedDefault.
  ///
  /// In en, this message translates to:
  /// **'Redeemed Ice Cream'**
  String get redemption_historyRedeemedDefault;

  /// No description provided for @dialog_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile?'**
  String get dialog_deleteTitle;

  /// No description provided for @dialog_deleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this profile? This action cannot be undone.'**
  String get dialog_deleteContent;

  /// No description provided for @dialog_confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get dialog_confirmDelete;

  /// No description provided for @dialog_cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get dialog_cancel;

  /// No description provided for @dialog_saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully!'**
  String get dialog_saveSuccess;

  /// No description provided for @notificationsetting_notificationBtn.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsetting_notificationBtn;

  /// No description provided for @notificationsetting_allnotificationBtn.
  ///
  /// In en, this message translates to:
  /// **'ALL NOTIFICATIONS'**
  String get notificationsetting_allnotificationBtn;

  /// No description provided for @notificationsetting_postBtn.
  ///
  /// In en, this message translates to:
  /// **'POST'**
  String get notificationsetting_postBtn;

  /// No description provided for @notificationsetting_likeBtn.
  ///
  /// In en, this message translates to:
  /// **'LIKE'**
  String get notificationsetting_likeBtn;

  /// No description provided for @notificationsetting_commentBtn.
  ///
  /// In en, this message translates to:
  /// **'COMMENT'**
  String get notificationsetting_commentBtn;

  /// No description provided for @videodetail_activitynameBtn.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY NAME'**
  String get videodetail_activitynameBtn;

  /// No description provided for @videodetail_nameBtn.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get videodetail_nameBtn;

  /// No description provided for @videodetail_DescriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get videodetail_DescriptionBtn;

  /// No description provided for @videodetail_descriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'description'**
  String get videodetail_descriptionBtn;

  /// No description provided for @videodetail_howtoplayBtn.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY / INSTRUCTIONS:'**
  String get videodetail_howtoplayBtn;

  /// No description provided for @videodetail_contentBtn.
  ///
  /// In en, this message translates to:
  /// **'content'**
  String get videodetail_contentBtn;

  /// No description provided for @videodetail_startBtn.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get videodetail_startBtn;

  /// No description provided for @videodetail_addBtn.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get videodetail_addBtn;

  /// No description provided for @videodetail_videoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Video Not Available (HTML Content Missing)'**
  String get videodetail_videoNotAvailable;

  /// No description provided for @videodetail_activityNameLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY NAME:'**
  String get videodetail_activityNameLabel;

  /// No description provided for @videodetail_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION:'**
  String get videodetail_descriptionLabel;

  /// No description provided for @videodetail_howToPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY / INSTRUCTIONS:'**
  String get videodetail_howToPlayLabel;

  /// No description provided for @videodetail_categoryPrefix.
  ///
  /// In en, this message translates to:
  /// **'Category: '**
  String get videodetail_categoryPrefix;

  /// No description provided for @videodetail_difficultyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Difficulty: '**
  String get videodetail_difficultyPrefix;

  /// No description provided for @videodetail_maxScorePrefix.
  ///
  /// In en, this message translates to:
  /// **'Max Score: '**
  String get videodetail_maxScorePrefix;

  /// No description provided for @addchild_namesurnameBtn.
  ///
  /// In en, this message translates to:
  /// **'NAME & SURNAME (CHILDREN)'**
  String get addchild_namesurnameBtn;

  /// No description provided for @addchild_errorName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get addchild_errorName;

  /// No description provided for @addchild_birthdayBtn.
  ///
  /// In en, this message translates to:
  /// **'BIRTHDAY : DD/MM/YYYY'**
  String get addchild_birthdayBtn;

  /// No description provided for @addchild_okBtn.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get addchild_okBtn;

  /// No description provided for @addchild_logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get addchild_logoutTitle;

  /// No description provided for @addchild_logoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one child to use the app. Are you sure you want to log out?'**
  String get addchild_logoutMsg;

  /// No description provided for @addchild_errorRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields (name, birthday, relationship).'**
  String get addchild_errorRequiredFields;

  /// No description provided for @childnamesetting_editnameBtn.
  ///
  /// In en, this message translates to:
  /// **'EDIT NAME'**
  String get childnamesetting_editnameBtn;

  /// No description provided for @childnamesetting_saveBtn.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get childnamesetting_saveBtn;

  /// No description provided for @managechild_manageprofileBtn.
  ///
  /// In en, this message translates to:
  /// **'MANAGE PROFILE'**
  String get managechild_manageprofileBtn;

  /// No description provided for @managechild_nameBtn.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get managechild_nameBtn;

  /// No description provided for @managechild_medalsandredemptionBtn.
  ///
  /// In en, this message translates to:
  /// **'MEDALS & REDEMPTION'**
  String get managechild_medalsandredemptionBtn;

  /// No description provided for @managechild_deleteprofileBtn.
  ///
  /// In en, this message translates to:
  /// **'DELETE PROFILE'**
  String get managechild_deleteprofileBtn;

  /// No description provided for @dairyactivity_playhistoryBtn.
  ///
  /// In en, this message translates to:
  /// **'PLAYING HISTORY'**
  String get dairyactivity_playhistoryBtn;

  /// No description provided for @dairyactivity_timeBtn.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get dairyactivity_timeBtn;

  /// No description provided for @dairyactivity_medalsBtn.
  ///
  /// In en, this message translates to:
  /// **'medals'**
  String get dairyactivity_medalsBtn;

  /// No description provided for @medalredemption_addrewardBtn.
  ///
  /// In en, this message translates to:
  /// **'ADD AGREEMENT'**
  String get medalredemption_addrewardBtn;

  /// No description provided for @medalredemption_rewardnameBtn.
  ///
  /// In en, this message translates to:
  /// **'Agreement Name'**
  String get medalredemption_rewardnameBtn;

  /// No description provided for @medalredemption_costBtn.
  ///
  /// In en, this message translates to:
  /// **'Cost (Points)'**
  String get medalredemption_costBtn;

  /// No description provided for @medalredemption_cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get medalredemption_cancelBtn;

  /// No description provided for @medalredemption_addBtn.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get medalredemption_addBtn;

  /// No description provided for @medalredemption_redemptionBtn.
  ///
  /// In en, this message translates to:
  /// **'AGREEMENTS'**
  String get medalredemption_redemptionBtn;

  /// No description provided for @medalredemption_activitiesBtn.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITIES'**
  String get medalredemption_activitiesBtn;

  /// No description provided for @medalredemption_currentscoreBtn.
  ///
  /// In en, this message translates to:
  /// **'CURRENT SCORE'**
  String get medalredemption_currentscoreBtn;

  /// No description provided for @medalredemption_rewardshopBtn.
  ///
  /// In en, this message translates to:
  /// **'AGREEMENTS'**
  String get medalredemption_rewardshopBtn;

  /// No description provided for @medalredemption_successfullyBtn.
  ///
  /// In en, this message translates to:
  /// **'Successfully Redeemed'**
  String get medalredemption_successfullyBtn;

  /// No description provided for @agreement_typeTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get agreement_typeTime;

  /// No description provided for @agreement_typeItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get agreement_typeItem;

  /// No description provided for @agreement_typePrivilege.
  ///
  /// In en, this message translates to:
  /// **'Privilege'**
  String get agreement_typePrivilege;

  /// No description provided for @agreement_typeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get agreement_typeFamily;

  /// No description provided for @agreement_selectType.
  ///
  /// In en, this message translates to:
  /// **'Select Agreement Type'**
  String get agreement_selectType;

  /// No description provided for @agreement_confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Agreement'**
  String get agreement_confirmTitle;

  /// No description provided for @agreement_confirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Use {cost} points to redeem \"{name}\"?'**
  String agreement_confirmMsg(int cost, String name);

  /// No description provided for @agreement_confirmBtn.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get agreement_confirmBtn;

  /// No description provided for @agreement_sessionActive.
  ///
  /// In en, this message translates to:
  /// **'Session Active'**
  String get agreement_sessionActive;

  /// No description provided for @agreement_timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get agreement_timeRemaining;

  /// No description provided for @agreement_startTimer.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get agreement_startTimer;

  /// No description provided for @agreement_stopTimer.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get agreement_stopTimer;

  /// No description provided for @agreement_endSession.
  ///
  /// In en, this message translates to:
  /// **'END SESSION'**
  String get agreement_endSession;

  /// No description provided for @agreement_sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete!'**
  String get agreement_sessionComplete;

  /// No description provided for @agreement_behaviorTitle.
  ///
  /// In en, this message translates to:
  /// **'How was the behavior?'**
  String get agreement_behaviorTitle;

  /// No description provided for @agreement_behaviorGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get agreement_behaviorGood;

  /// No description provided for @agreement_behaviorOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get agreement_behaviorOk;

  /// No description provided for @agreement_behaviorBad.
  ///
  /// In en, this message translates to:
  /// **'Needs Improvement'**
  String get agreement_behaviorBad;

  /// No description provided for @agreement_bonusMsg.
  ///
  /// In en, this message translates to:
  /// **'Bonus: +{points} points'**
  String agreement_bonusMsg(int points);

  /// No description provided for @agreement_deductMsg.
  ///
  /// In en, this message translates to:
  /// **'Deduction: -{points} points'**
  String agreement_deductMsg(int points);

  /// No description provided for @agreement_noChange.
  ///
  /// In en, this message translates to:
  /// **'No point change'**
  String get agreement_noChange;

  /// No description provided for @agreement_notEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough points! Need {needed} more.'**
  String agreement_notEnoughPoints(int needed);

  /// No description provided for @agreement_durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get agreement_durationLabel;

  /// No description provided for @agreement_emptyList.
  ///
  /// In en, this message translates to:
  /// **'No agreements yet'**
  String get agreement_emptyList;

  /// No description provided for @agreement_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a new agreement'**
  String get agreement_emptyHint;

  /// No description provided for @physical_snackNoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Please attach video or image evidence.'**
  String get physical_snackNoEvidence;

  /// No description provided for @physical_snackInvalidScore.
  ///
  /// In en, this message translates to:
  /// **'Please set a valid score (1 to {maxScore}).'**
  String physical_snackInvalidScore(int maxScore);

  /// No description provided for @physical_dialogSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Complete!'**
  String get physical_dialogSubmitTitle;

  /// No description provided for @physical_dialogSubmitContent.
  ///
  /// In en, this message translates to:
  /// **'Your evidence has been submitted for approval.'**
  String get physical_dialogSubmitContent;

  /// No description provided for @physical_dialogOkBtn.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get physical_dialogOkBtn;

  /// No description provided for @physical_snackSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Submission Error: {error}'**
  String physical_snackSubmitError(String error);

  /// No description provided for @physical_dialogEnterScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Score'**
  String get physical_dialogEnterScoreTitle;

  /// No description provided for @physical_dialogEnterScoreHint.
  ///
  /// In en, this message translates to:
  /// **'Enter score (1-{maxScore})'**
  String physical_dialogEnterScoreHint(int maxScore);

  /// No description provided for @physical_dialogCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get physical_dialogCancelBtn;

  /// No description provided for @physical_snackInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid score (0-{maxScore})'**
  String physical_snackInvalidInput(int maxScore);

  /// No description provided for @physical_stopBtn.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get physical_stopBtn;

  /// No description provided for @physical_startBtn.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get physical_startBtn;

  /// No description provided for @physical_takePhotoBtn.
  ///
  /// In en, this message translates to:
  /// **'TAKE PHOTO'**
  String get physical_takePhotoBtn;

  /// No description provided for @physical_medalsScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'MEDALS / SCORE'**
  String get physical_medalsScoreLabel;

  /// No description provided for @physical_diaryLabel.
  ///
  /// In en, this message translates to:
  /// **'DIARY'**
  String get physical_diaryLabel;

  /// No description provided for @physical_diaryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter notes here...'**
  String get physical_diaryHint;

  /// No description provided for @physical_imageEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'IMAGE EVIDENCE'**
  String get physical_imageEvidenceLabel;

  /// No description provided for @physical_videoEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'VIDEO EVIDENCE'**
  String get physical_videoEvidenceLabel;

  /// No description provided for @physical_timeLabel.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get physical_timeLabel;

  /// No description provided for @physical_submittingBtn.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get physical_submittingBtn;

  /// No description provided for @physical_finishBtn.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get physical_finishBtn;

  /// No description provided for @physical_addChildren.
  ///
  /// In en, this message translates to:
  /// **'Add Children'**
  String get physical_addChildren;

  /// No description provided for @physical_addChildrenDesc.
  ///
  /// In en, this message translates to:
  /// **'Select children to play together'**
  String get physical_addChildrenDesc;

  /// No description provided for @physical_childrenAdded.
  ///
  /// In en, this message translates to:
  /// **'+{count} children'**
  String physical_childrenAdded(int count);

  /// No description provided for @physical_currentChild.
  ///
  /// In en, this message translates to:
  /// **'Currently playing'**
  String get physical_currentChild;

  /// No description provided for @physical_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get physical_confirm;

  /// No description provided for @languagedetail_titlePrefix.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE: '**
  String get languagedetail_titlePrefix;

  /// No description provided for @languagedetail_categoryPrefix.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY: '**
  String get languagedetail_categoryPrefix;

  /// No description provided for @languagedetail_activityTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY TITLE'**
  String get languagedetail_activityTitleLabel;

  /// No description provided for @languagedetail_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get languagedetail_descriptionLabel;

  /// No description provided for @languagedetail_difficultyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Difficulty: '**
  String get languagedetail_difficultyPrefix;

  /// No description provided for @languagedetail_maxScorePrefix.
  ///
  /// In en, this message translates to:
  /// **'Max Score: '**
  String get languagedetail_maxScorePrefix;

  /// No description provided for @languagedetail_startBtn.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get languagedetail_startBtn;

  /// No description provided for @languagedetail_openInYoutube.
  ///
  /// In en, this message translates to:
  /// **'Open in YouTube (TV)'**
  String get languagedetail_openInYoutube;

  /// No description provided for @itemintro_recordToEnable.
  ///
  /// In en, this message translates to:
  /// **'Record to enable playback'**
  String get itemintro_recordToEnable;

  /// No description provided for @itemintro_listenExampleBtn.
  ///
  /// In en, this message translates to:
  /// **'LISTEN TO EXAMPLE'**
  String get itemintro_listenExampleBtn;

  /// No description provided for @itemintro_practiceNowBtn.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE NOW'**
  String get itemintro_practiceNowBtn;

  /// No description provided for @itemintro_submitBtn.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT'**
  String get itemintro_submitBtn;

  /// No description provided for @itemintro_playsection.
  ///
  /// In en, this message translates to:
  /// **'PLAY SECTION'**
  String get itemintro_playsection;

  /// No description provided for @itemintro_record.
  ///
  /// In en, this message translates to:
  /// **'RECORD'**
  String get itemintro_record;

  /// No description provided for @itemintro_casttotv.
  ///
  /// In en, this message translates to:
  /// **'CAST TO TV'**
  String get itemintro_casttotv;

  /// No description provided for @itemintro_airplay.
  ///
  /// In en, this message translates to:
  /// **'AIRPLAY'**
  String get itemintro_airplay;

  /// No description provided for @itemintro_previous.
  ///
  /// In en, this message translates to:
  /// **'< PREVIOUS'**
  String get itemintro_previous;

  /// No description provided for @itemintro_next.
  ///
  /// In en, this message translates to:
  /// **'NEXT >'**
  String get itemintro_next;

  /// No description provided for @itemintro_finish.
  ///
  /// In en, this message translates to:
  /// **'FINISH >'**
  String get itemintro_finish;

  /// No description provided for @itemintro_Videonotavailable.
  ///
  /// In en, this message translates to:
  /// **'Video not available'**
  String get itemintro_Videonotavailable;

  /// No description provided for @record_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get record_loading;

  /// No description provided for @record_finishBtn.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get record_finishBtn;

  /// No description provided for @record_errorMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone error or permission denied'**
  String get record_errorMic;

  /// No description provided for @record_statusRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get record_statusRecording;

  /// No description provided for @record_statusIdle.
  ///
  /// In en, this message translates to:
  /// **'Press mic to record'**
  String get record_statusIdle;

  /// No description provided for @result_activityCompletedDefault.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY COMPLETED'**
  String get result_activityCompletedDefault;

  /// No description provided for @result_greatJobTitle.
  ///
  /// In en, this message translates to:
  /// **'GREAT JOB!'**
  String get result_greatJobTitle;

  /// No description provided for @result_totalScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get result_totalScoreLabel;

  /// No description provided for @result_timeSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Spent'**
  String get result_timeSpentLabel;

  /// No description provided for @result_retryBtn.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get result_retryBtn;

  /// No description provided for @result_backToActivitiesBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK TO ACTIVITIES'**
  String get result_backToActivitiesBtn;

  /// No description provided for @result_returnHomeBtn.
  ///
  /// In en, this message translates to:
  /// **'RETURN HOME'**
  String get result_returnHomeBtn;

  /// No description provided for @result_timeFormat.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String result_timeFormat(int minutes, int seconds);

  /// No description provided for @calculate_title.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE'**
  String get calculate_title;

  /// No description provided for @calculate_plusBtn.
  ///
  /// In en, this message translates to:
  /// **'PLUS +'**
  String get calculate_plusBtn;

  /// No description provided for @calculate_minusBtn.
  ///
  /// In en, this message translates to:
  /// **'MINUS -'**
  String get calculate_minusBtn;

  /// No description provided for @calculate_multiplyBtn.
  ///
  /// In en, this message translates to:
  /// **'MULTIPLY *'**
  String get calculate_multiplyBtn;

  /// No description provided for @calculate_divideBtn.
  ///
  /// In en, this message translates to:
  /// **'DEVIDE /'**
  String get calculate_divideBtn;

  /// No description provided for @calculate_mixBtn.
  ///
  /// In en, this message translates to:
  /// **'MIX + - * /'**
  String get calculate_mixBtn;

  /// No description provided for @languagehub_searchHint.
  ///
  /// In en, this message translates to:
  /// **'search...'**
  String get languagehub_searchHint;

  /// No description provided for @languagehub_trainingTitle.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE TRAINING'**
  String get languagehub_trainingTitle;

  /// No description provided for @languagehub_listeningSpeakingTitle.
  ///
  /// In en, this message translates to:
  /// **'LISTENING AND SPEAKING'**
  String get languagehub_listeningSpeakingTitle;

  /// No description provided for @languagehub_easyBtn.
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get languagehub_easyBtn;

  /// No description provided for @languagehub_mediumBtn.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get languagehub_mediumBtn;

  /// No description provided for @languagehub_difficultBtn.
  ///
  /// In en, this message translates to:
  /// **'DIFFICULT'**
  String get languagehub_difficultBtn;

  /// No description provided for @plus_castToTvBtn.
  ///
  /// In en, this message translates to:
  /// **'CAST TO TV'**
  String get plus_castToTvBtn;

  /// No description provided for @plus_answerBtn.
  ///
  /// In en, this message translates to:
  /// **'ANSWER'**
  String get plus_answerBtn;

  /// No description provided for @createpost_sharesus.
  ///
  /// In en, this message translates to:
  /// **'Post shared successfully!'**
  String get createpost_sharesus;

  /// No description provided for @createpost_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred:'**
  String get createpost_error;

  /// No description provided for @createpost_newpost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get createpost_newpost;

  /// No description provided for @createpost_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get createpost_share;

  /// No description provided for @createpost_picksomepicture.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a picture'**
  String get createpost_picksomepicture;

  /// No description provided for @createpost_changepic.
  ///
  /// In en, this message translates to:
  /// **'Change picture'**
  String get createpost_changepic;

  /// No description provided for @createpost_writecaption.
  ///
  /// In en, this message translates to:
  /// **'Write a caption...'**
  String get createpost_writecaption;

  /// No description provided for @languagelist_snackNotConnected.
  ///
  /// In en, this message translates to:
  /// **'This flow is not connected to activities yet.'**
  String get languagelist_snackNotConnected;

  /// No description provided for @common_categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get common_categoryLabel;

  /// No description provided for @common_difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get common_difficultyLabel;

  /// No description provided for @common_maxScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Score'**
  String get common_maxScoreLabel;

  /// No description provided for @common_categoryLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get common_categoryLanguage;

  /// No description provided for @common_categoryPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get common_categoryPhysical;

  /// No description provided for @common_categoryCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get common_categoryCalculate;

  /// No description provided for @common_activityLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language Activity'**
  String get common_activityLanguage;

  /// No description provided for @common_activityPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical Activity'**
  String get common_activityPhysical;

  /// No description provided for @common_activityCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculation Activity'**
  String get common_activityCalculate;

  /// No description provided for @common_difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get common_difficultyEasy;

  /// No description provided for @common_difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get common_difficultyMedium;

  /// No description provided for @common_difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get common_difficultyHard;

  /// No description provided for @createActivity_title.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACTIVITY'**
  String get createActivity_title;

  /// No description provided for @createActivity_selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get createActivity_selectCategory;

  /// No description provided for @createActivity_physical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get createActivity_physical;

  /// No description provided for @createActivity_calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get createActivity_calculate;

  /// No description provided for @createActivity_name.
  ///
  /// In en, this message translates to:
  /// **'Activity Name'**
  String get createActivity_name;

  /// No description provided for @createActivity_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createActivity_description;

  /// No description provided for @createActivity_content.
  ///
  /// In en, this message translates to:
  /// **'How to Play / Instructions'**
  String get createActivity_content;

  /// No description provided for @createActivity_difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get createActivity_difficulty;

  /// No description provided for @createActivity_maxScore.
  ///
  /// In en, this message translates to:
  /// **'Max Score'**
  String get createActivity_maxScore;

  /// No description provided for @createActivity_videoUrl.
  ///
  /// In en, this message translates to:
  /// **'Video URL (TikTok)'**
  String get createActivity_videoUrl;

  /// No description provided for @createActivity_addQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get createActivity_addQuestion;

  /// No description provided for @createActivity_question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get createActivity_question;

  /// No description provided for @createActivity_answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get createActivity_answer;

  /// No description provided for @createActivity_solution.
  ///
  /// In en, this message translates to:
  /// **'Solution / Explanation'**
  String get createActivity_solution;

  /// No description provided for @createActivity_score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get createActivity_score;

  /// No description provided for @createActivity_submit.
  ///
  /// In en, this message translates to:
  /// **'CREATE'**
  String get createActivity_submit;

  /// No description provided for @createActivity_success.
  ///
  /// In en, this message translates to:
  /// **'Activity created successfully!'**
  String get createActivity_success;

  /// No description provided for @createActivity_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to create activity'**
  String get createActivity_error;

  /// No description provided for @createActivity_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an activity name'**
  String get createActivity_nameRequired;

  /// No description provided for @createActivity_contentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter instructions'**
  String get createActivity_contentRequired;

  /// No description provided for @createActivity_needQuestions.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one question'**
  String get createActivity_needQuestions;

  /// No description provided for @createActivity_questionNo.
  ///
  /// In en, this message translates to:
  /// **'Question {index}'**
  String createActivity_questionNo(int index);

  /// No description provided for @createActivity_removeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get createActivity_removeQuestion;

  /// No description provided for @createActivity_creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get createActivity_creating;

  /// No description provided for @profile_myActivities.
  ///
  /// In en, this message translates to:
  /// **'MY ACTIVITIES'**
  String get profile_myActivities;

  /// No description provided for @profile_noActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get profile_noActivities;

  /// No description provided for @profile_editActivity.
  ///
  /// In en, this message translates to:
  /// **'Edit Activity'**
  String get profile_editActivity;

  /// No description provided for @profile_deleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete Activity'**
  String get profile_deleteActivity;

  /// No description provided for @profile_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String profile_deleteConfirm(String name);

  /// No description provided for @profile_deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity deleted'**
  String get profile_deleteSuccess;

  /// No description provided for @profile_updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity updated'**
  String get profile_updateSuccess;

  /// No description provided for @profile_save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get profile_save;

  /// No description provided for @profile_manage.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get profile_manage;

  /// No description provided for @share_title.
  ///
  /// In en, this message translates to:
  /// **'SHARE RESULT'**
  String get share_title;

  /// No description provided for @share_asImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get share_asImage;

  /// No description provided for @share_asText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get share_asText;

  /// No description provided for @share_greatJob.
  ///
  /// In en, this message translates to:
  /// **'GREAT JOB!'**
  String get share_greatJob;

  /// No description provided for @share_keepTrying.
  ///
  /// In en, this message translates to:
  /// **'KEEP TRYING!'**
  String get share_keepTrying;

  /// No description provided for @share_textTemplate.
  ///
  /// In en, this message translates to:
  /// **'I scored {score}/{maxScore} on \"{activityName}\" in Skill Wallet Kizuna!'**
  String share_textTemplate(String activityName, int score, int maxScore);

  /// No description provided for @common_loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get common_loginFailed;

  /// No description provided for @common_errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String common_errorGeneric(String msg);

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get common_processing;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_noServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get common_noServer;

  /// No description provided for @audio_tooShort.
  ///
  /// In en, this message translates to:
  /// **'Audio data too short — try again'**
  String get audio_tooShort;

  /// No description provided for @audio_notFound.
  ///
  /// In en, this message translates to:
  /// **'Audio file not found — try again'**
  String get audio_notFound;

  /// No description provided for @audio_analyseFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed — try again'**
  String get audio_analyseFailed;

  /// No description provided for @calculate_restartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart?'**
  String get calculate_restartTitle;

  /// No description provided for @calculate_restartMsg.
  ///
  /// In en, this message translates to:
  /// **'Time and answers will be reset'**
  String get calculate_restartMsg;

  /// No description provided for @calculate_restartBtn.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get calculate_restartBtn;

  /// No description provided for @calculate_solutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer #{index}'**
  String calculate_solutionTitle(int index);

  /// No description provided for @calculate_questionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question:'**
  String get calculate_questionLabel;

  /// No description provided for @calculate_answerLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer:'**
  String get calculate_answerLabel;

  /// No description provided for @calculate_pressStart.
  ///
  /// In en, this message translates to:
  /// **'Press START button to begin timing'**
  String get calculate_pressStart;

  /// No description provided for @calculate_questionsAfterTimer.
  ///
  /// In en, this message translates to:
  /// **'Questions will appear after timing completes'**
  String get calculate_questionsAfterTimer;

  /// No description provided for @calculate_failedPickFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick file: {error}'**
  String calculate_failedPickFile(String error);

  /// No description provided for @calculate_childIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Child ID not found. Please login again.'**
  String get calculate_childIdNotFound;

  /// No description provided for @calculate_errorCompleting.
  ///
  /// In en, this message translates to:
  /// **'Error completing activity: {error}'**
  String calculate_errorCompleting(String error);

  /// No description provided for @itemintro_videoLoading.
  ///
  /// In en, this message translates to:
  /// **'Please wait. Video is loading...'**
  String get itemintro_videoLoading;

  /// No description provided for @itemintro_timingIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Timing data for this sentence is incomplete'**
  String get itemintro_timingIncomplete;

  /// No description provided for @itemintro_videoPlayError.
  ///
  /// In en, this message translates to:
  /// **'Cannot play video: {error}'**
  String itemintro_videoPlayError(String error);

  /// No description provided for @itemintro_micPermission.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone access'**
  String get itemintro_micPermission;

  /// No description provided for @itemintro_recordStartError.
  ///
  /// In en, this message translates to:
  /// **'Cannot start recording: {error}'**
  String itemintro_recordStartError(String error);

  /// No description provided for @itemintro_recordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Recording too short. Please try again'**
  String get itemintro_recordTooShort;

  /// No description provided for @itemintro_evalResult.
  ///
  /// In en, this message translates to:
  /// **'Evaluation result: {score}% - \"{text}\"'**
  String itemintro_evalResult(int score, String text);

  /// No description provided for @itemintro_questError.
  ///
  /// In en, this message translates to:
  /// **'Error completing quest: {error}'**
  String itemintro_questError(String error);

  /// No description provided for @itemintro_playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to play back recording.'**
  String get itemintro_playbackFailed;

  /// No description provided for @record_micDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied.'**
  String get record_micDenied;

  /// No description provided for @record_recordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording failed.'**
  String get record_recordingFailed;

  /// No description provided for @record_playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio.'**
  String get record_playbackFailed;

  /// No description provided for @record_noValidAudio.
  ///
  /// In en, this message translates to:
  /// **'Error: No valid audio recorded.'**
  String get record_noValidAudio;

  /// No description provided for @record_aiError.
  ///
  /// In en, this message translates to:
  /// **'AI Error: {error}'**
  String record_aiError(String error);

  /// No description provided for @medals_noActivityHistory.
  ///
  /// In en, this message translates to:
  /// **'No activity history'**
  String get medals_noActivityHistory;

  /// No description provided for @medals_noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get medals_noHistory;

  /// No description provided for @post_noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get post_noComments;

  /// No description provided for @namesetting_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot save name. Please try again.'**
  String get namesetting_saveFailed;

  /// No description provided for @activityCard_selectChild.
  ///
  /// In en, this message translates to:
  /// **'Please select a child'**
  String get activityCard_selectChild;

  /// No description provided for @activityCard_selectChildMsg.
  ///
  /// In en, this message translates to:
  /// **'You must select a child before playing activities'**
  String get activityCard_selectChildMsg;

  /// No description provided for @activityCard_goSelect.
  ///
  /// In en, this message translates to:
  /// **'Go select child'**
  String get activityCard_goSelect;

  /// No description provided for @childsetting_addSuccess.
  ///
  /// In en, this message translates to:
  /// **'Child added successfully'**
  String get childsetting_addSuccess;

  /// No description provided for @childsetting_deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Child deleted successfully'**
  String get childsetting_deleteSuccess;

  /// No description provided for @childsetting_selectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Child selected successfully'**
  String get childsetting_selectSuccess;

  /// No description provided for @childsetting_noChildren.
  ///
  /// In en, this message translates to:
  /// **'No children in system'**
  String get childsetting_noChildren;

  /// No description provided for @childsetting_addChild.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get childsetting_addChild;

  /// No description provided for @childsetting_active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get childsetting_active;

  /// No description provided for @childsetting_select.
  ///
  /// In en, this message translates to:
  /// **'SELECT'**
  String get childsetting_select;

  /// No description provided for @common_selectSource.
  ///
  /// In en, this message translates to:
  /// **'Select Source'**
  String get common_selectSource;

  /// No description provided for @common_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get common_camera;

  /// No description provided for @common_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get common_gallery;

  /// No description provided for @common_pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get common_pickFromGallery;

  /// No description provided for @common_useGooglePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use Google profile photo'**
  String get common_useGooglePhoto;

  /// No description provided for @common_useFacebookPhoto.
  ///
  /// In en, this message translates to:
  /// **'Use Facebook profile photo'**
  String get common_useFacebookPhoto;

  /// No description provided for @common_useOriginalPhoto.
  ///
  /// In en, this message translates to:
  /// **'Use previous profile photo'**
  String get common_useOriginalPhoto;

  /// No description provided for @common_uploadPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed'**
  String get common_uploadPhotoFailed;

  /// No description provided for @common_photoNotFound.
  ///
  /// In en, this message translates to:
  /// **'No profile photo found from {provider}'**
  String common_photoNotFound(String provider);

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_submit.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT'**
  String get common_submit;

  /// No description provided for @common_addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get common_addImage;

  /// No description provided for @common_addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add Video'**
  String get common_addVideo;

  /// No description provided for @common_videoAdded.
  ///
  /// In en, this message translates to:
  /// **'Video Added'**
  String get common_videoAdded;

  /// No description provided for @common_image.
  ///
  /// In en, this message translates to:
  /// **'IMAGE'**
  String get common_image;

  /// No description provided for @common_video.
  ///
  /// In en, this message translates to:
  /// **'VIDEO'**
  String get common_video;

  /// No description provided for @common_howToPlay.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get common_howToPlay;

  /// No description provided for @common_questions.
  ///
  /// In en, this message translates to:
  /// **'QUESTIONS'**
  String get common_questions;

  /// No description provided for @common_evidence.
  ///
  /// In en, this message translates to:
  /// **'EVIDENCE'**
  String get common_evidence;

  /// No description provided for @common_finish.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get common_finish;

  /// No description provided for @common_start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get common_start;

  /// No description provided for @common_restart.
  ///
  /// In en, this message translates to:
  /// **'RESTART'**
  String get common_restart;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get common_done;

  /// No description provided for @common_submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get common_submitting;

  /// No description provided for @common_score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get common_score;

  /// No description provided for @calculate_noAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer available'**
  String get calculate_noAnswer;

  /// No description provided for @calculate_answer.
  ///
  /// In en, this message translates to:
  /// **'ANSWER'**
  String get calculate_answer;

  /// No description provided for @calculate_answerAgain.
  ///
  /// In en, this message translates to:
  /// **'ANSWER AGAIN'**
  String get calculate_answerAgain;

  /// No description provided for @calculate_stopBeforeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Stop timer before answering'**
  String get calculate_stopBeforeAnswer;

  /// No description provided for @calculate_yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer: {answer}'**
  String calculate_yourAnswer(String answer);

  /// No description provided for @calculate_typeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get calculate_typeAnswer;

  /// No description provided for @calculate_diaryNotes.
  ///
  /// In en, this message translates to:
  /// **'DIARY / NOTES'**
  String get calculate_diaryNotes;

  /// No description provided for @calculate_writeNotes.
  ///
  /// In en, this message translates to:
  /// **'Write your notes here...'**
  String get calculate_writeNotes;

  /// No description provided for @calculate_noQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get calculate_noQuestions;

  /// No description provided for @calculate_confirmFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish?'**
  String get calculate_confirmFinishTitle;

  /// No description provided for @calculate_confirmFinishMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish? You cannot restart the timer.'**
  String get calculate_confirmFinishMsg;

  /// No description provided for @calculate_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get calculate_descriptionLabel;

  /// No description provided for @calculate_solutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Solution:'**
  String get calculate_solutionLabel;

  /// No description provided for @calculate_correct.
  ///
  /// In en, this message translates to:
  /// **'CORRECT'**
  String get calculate_correct;

  /// No description provided for @calculate_incorrect.
  ///
  /// In en, this message translates to:
  /// **'INCORRECT'**
  String get calculate_incorrect;

  /// No description provided for @record_title.
  ///
  /// In en, this message translates to:
  /// **'RECORD'**
  String get record_title;

  /// No description provided for @itemintro_segmentOf.
  ///
  /// In en, this message translates to:
  /// **'Segment {current} of {total}'**
  String itemintro_segmentOf(int current, int total);

  /// No description provided for @itemintro_speak.
  ///
  /// In en, this message translates to:
  /// **'SPEAK'**
  String get itemintro_speak;

  /// No description provided for @itemintro_point.
  ///
  /// In en, this message translates to:
  /// **'POINT'**
  String get itemintro_point;

  /// No description provided for @itemintro_completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get itemintro_completed;

  /// No description provided for @itemintro_pausePlayback.
  ///
  /// In en, this message translates to:
  /// **'PAUSE PLAYBACK...'**
  String get itemintro_pausePlayback;

  /// No description provided for @itemintro_listenRecording.
  ///
  /// In en, this message translates to:
  /// **'LISTEN TO YOUR RECORDING'**
  String get itemintro_listenRecording;

  /// No description provided for @itemintro_recordToPlayback.
  ///
  /// In en, this message translates to:
  /// **'Record to enable playback'**
  String get itemintro_recordToPlayback;

  /// No description provided for @videodetail_previewNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Video Preview Not Available'**
  String get videodetail_previewNotAvailable;

  /// No description provided for @videodetail_openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser to Watch'**
  String get videodetail_openInBrowser;

  /// No description provided for @videodetail_openTiktok.
  ///
  /// In en, this message translates to:
  /// **'OPEN TIKTOK'**
  String get videodetail_openTiktok;

  /// No description provided for @videodetail_openInTiktokTV.
  ///
  /// In en, this message translates to:
  /// **'Open in TikTok (TV)'**
  String get videodetail_openInTiktokTV;

  /// No description provided for @videodetail_noVideoUrl.
  ///
  /// In en, this message translates to:
  /// **'No video URL available'**
  String get videodetail_noVideoUrl;

  /// No description provided for @calculate_tvMode.
  ///
  /// In en, this message translates to:
  /// **'TV Mode'**
  String get calculate_tvMode;

  /// No description provided for @calculate_tvModeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see next problem'**
  String get calculate_tvModeHint;

  /// No description provided for @calculate_questionsCount.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get calculate_questionsCount;

  /// No description provided for @calculate_tvModeBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Share to TV'**
  String get calculate_tvModeBannerTitle;

  /// No description provided for @calculate_tvModeBannerSub.
  ///
  /// In en, this message translates to:
  /// **'Show problems on big screen'**
  String get calculate_tvModeBannerSub;

  /// No description provided for @languagehub_appTitle.
  ///
  /// In en, this message translates to:
  /// **'KRATON'**
  String get languagehub_appTitle;

  /// No description provided for @languagehub_fillInBlanksTitle.
  ///
  /// In en, this message translates to:
  /// **'FILL IN THE BLANKS'**
  String get languagehub_fillInBlanksTitle;

  /// No description provided for @result_resultTitle.
  ///
  /// In en, this message translates to:
  /// **'RESULT'**
  String get result_resultTitle;

  /// No description provided for @result_totalScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'TOTAL SCORE'**
  String get result_totalScoreTitle;

  /// No description provided for @result_keepTryingTitle.
  ///
  /// In en, this message translates to:
  /// **'KEEP TRYING!'**
  String get result_keepTryingTitle;

  /// No description provided for @result_timeSpentPrefix.
  ///
  /// In en, this message translates to:
  /// **'TIME SPENT: '**
  String get result_timeSpentPrefix;

  /// No description provided for @result_playAgainBtn.
  ///
  /// In en, this message translates to:
  /// **'PLAY AGAIN'**
  String get result_playAgainBtn;

  /// No description provided for @plus_title.
  ///
  /// In en, this message translates to:
  /// **'PLUS +'**
  String get plus_title;

  /// No description provided for @plus_questionTitle.
  ///
  /// In en, this message translates to:
  /// **'QUESTION'**
  String get plus_questionTitle;

  /// No description provided for @plus_startBtn.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get plus_startBtn;

  /// No description provided for @answerplus_title.
  ///
  /// In en, this message translates to:
  /// **'ANSWER PLUS +'**
  String get answerplus_title;

  /// No description provided for @answerplus_questionLabel.
  ///
  /// In en, this message translates to:
  /// **'QUESTION'**
  String get answerplus_questionLabel;

  /// No description provided for @answerplus_answerLabel.
  ///
  /// In en, this message translates to:
  /// **'ANSWER'**
  String get answerplus_answerLabel;

  /// No description provided for @email_loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login with Email'**
  String get email_loginTitle;

  /// No description provided for @email_registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get email_registerTitle;

  /// No description provided for @email_emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email_emailHint;

  /// No description provided for @email_passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get email_passwordHint;

  /// No description provided for @email_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get email_nameHint;

  /// No description provided for @email_loginBtn.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get email_loginBtn;

  /// No description provided for @email_registerBtn.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get email_registerBtn;

  /// No description provided for @email_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get email_forgotPassword;

  /// No description provided for @email_noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get email_noAccount;

  /// No description provided for @email_hasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get email_hasAccount;

  /// No description provided for @email_resetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get email_resetSent;

  /// No description provided for @email_passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get email_passwordTooShort;

  /// No description provided for @email_enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get email_enterEmail;

  /// No description provided for @email_enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get email_enterPassword;

  /// No description provided for @email_enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get email_enterName;

  /// No description provided for @email_forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get email_forgotTitle;

  /// No description provided for @email_forgotMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset link.'**
  String get email_forgotMsg;

  /// No description provided for @email_sendReset.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get email_sendReset;

  /// No description provided for @email_loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'LOGIN WITH EMAIL'**
  String get email_loginWithEmail;

  /// No description provided for @email_confirmSent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation email sent. Please check your inbox and click the link to verify, then log in.'**
  String get email_confirmSent;

  /// No description provided for @email_confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get email_confirmPasswordHint;

  /// No description provided for @email_passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get email_passwordsDoNotMatch;

  /// No description provided for @register_childNameHint.
  ///
  /// In en, this message translates to:
  /// **'First - Last Name'**
  String get register_childNameHint;

  /// No description provided for @register_birthdayHint.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get register_birthdayHint;

  /// No description provided for @relation_label.
  ///
  /// In en, this message translates to:
  /// **'RELATIONSHIP'**
  String get relation_label;

  /// No description provided for @relation_hint.
  ///
  /// In en, this message translates to:
  /// **'Select relationship'**
  String get relation_hint;

  /// No description provided for @relation_parent.
  ///
  /// In en, this message translates to:
  /// **'Father/Mother'**
  String get relation_parent;

  /// No description provided for @relation_grandparentPaternal.
  ///
  /// In en, this message translates to:
  /// **'Grandfather/Grandmother (Father\'s side)'**
  String get relation_grandparentPaternal;

  /// No description provided for @relation_grandparentMaternal.
  ///
  /// In en, this message translates to:
  /// **'Grandfather/Grandmother (Mother\'s side)'**
  String get relation_grandparentMaternal;

  /// No description provided for @relation_auntUncle.
  ///
  /// In en, this message translates to:
  /// **'Aunt/Uncle'**
  String get relation_auntUncle;

  /// No description provided for @relation_caregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get relation_caregiver;

  /// No description provided for @relation_nanny.
  ///
  /// In en, this message translates to:
  /// **'Nanny/Babysitter'**
  String get relation_nanny;

  /// No description provided for @activityhistory_selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get activityhistory_selectDate;

  /// No description provided for @activityhistory_times.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String activityhistory_times(int count);

  /// No description provided for @activityhistory_noHistory.
  ///
  /// In en, this message translates to:
  /// **'No activity history'**
  String get activityhistory_noHistory;

  /// No description provided for @activityhistory_inCategory.
  ///
  /// In en, this message translates to:
  /// **'In {category}'**
  String activityhistory_inCategory(String category);

  /// No description provided for @dailyactivity_playingHistory.
  ///
  /// In en, this message translates to:
  /// **'Playing history'**
  String get dailyactivity_playingHistory;

  /// No description provided for @dailyactivity_noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get dailyactivity_noData;

  /// No description provided for @dailyactivity_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get dailyactivity_activity;

  /// No description provided for @childprofile_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get childprofile_language;

  /// No description provided for @childprofile_physical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get childprofile_physical;

  /// No description provided for @childprofile_calculation.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get childprofile_calculation;

  /// No description provided for @childprofile_unknownName.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get childprofile_unknownName;

  /// No description provided for @childprofile_noHistory.
  ///
  /// In en, this message translates to:
  /// **'No activity history'**
  String get childprofile_noHistory;

  /// No description provided for @childprofile_startPlaying.
  ///
  /// In en, this message translates to:
  /// **'Start playing activities to see stats here'**
  String get childprofile_startPlaying;

  /// No description provided for @childprofile_totalActivities.
  ///
  /// In en, this message translates to:
  /// **'Total activities'**
  String get childprofile_totalActivities;

  /// No description provided for @childprofile_times.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get childprofile_times;

  /// No description provided for @medalredemption_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get medalredemption_activity;

  /// No description provided for @medalredemption_done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get medalredemption_done;

  /// No description provided for @medalredemption_points.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get medalredemption_points;

  /// No description provided for @playingresult_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get playingresult_activity;

  /// No description provided for @playingresult_title.
  ///
  /// In en, this message translates to:
  /// **'Playing result'**
  String get playingresult_title;

  /// No description provided for @playingresult_session.
  ///
  /// In en, this message translates to:
  /// **'Session {number}'**
  String playingresult_session(int number);

  /// No description provided for @playingresult_scoreObtained.
  ///
  /// In en, this message translates to:
  /// **'Score obtained'**
  String get playingresult_scoreObtained;

  /// No description provided for @playingresult_diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get playingresult_diary;

  /// No description provided for @playingresult_noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get playingresult_noNotes;

  /// No description provided for @playingresult_image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get playingresult_image;

  /// No description provided for @playingresult_video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get playingresult_video;

  /// No description provided for @playingresult_videoAttached.
  ///
  /// In en, this message translates to:
  /// **'Video attached'**
  String get playingresult_videoAttached;

  /// No description provided for @playingresult_timeSpent.
  ///
  /// In en, this message translates to:
  /// **'Time spent'**
  String get playingresult_timeSpent;

  /// No description provided for @playingresult_noImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get playingresult_noImage;

  /// No description provided for @playingresult_sentencesSpoken.
  ///
  /// In en, this message translates to:
  /// **'Sentences spoken'**
  String get playingresult_sentencesSpoken;

  /// No description provided for @playingresult_sentence.
  ///
  /// In en, this message translates to:
  /// **'Sentence {number}'**
  String playingresult_sentence(int number);

  /// No description provided for @playingresult_sentenceToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Sentence to speak:'**
  String get playingresult_sentenceToSpeak;

  /// No description provided for @playingresult_whatWasSpoken.
  ///
  /// In en, this message translates to:
  /// **'What was spoken:'**
  String get playingresult_whatWasSpoken;

  /// No description provided for @playingresult_noData.
  ///
  /// In en, this message translates to:
  /// **'(No data)'**
  String get playingresult_noData;

  /// No description provided for @playingresult_noSpeechData.
  ///
  /// In en, this message translates to:
  /// **'No speech data'**
  String get playingresult_noSpeechData;

  /// No description provided for @playingresult_answerResults.
  ///
  /// In en, this message translates to:
  /// **'Answer results'**
  String get playingresult_answerResults;

  /// No description provided for @playingresult_questionLabel.
  ///
  /// In en, this message translates to:
  /// **'Q.{number}'**
  String playingresult_questionLabel(int number);

  /// No description provided for @playingresult_questionFallback.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String playingresult_questionFallback(int number);

  /// No description provided for @summary_title.
  ///
  /// In en, this message translates to:
  /// **'Review Your Recording'**
  String get summary_title;

  /// No description provided for @summary_completeActivity.
  ///
  /// In en, this message translates to:
  /// **'Complete Activity'**
  String get summary_completeActivity;

  /// No description provided for @summary_segmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Segment {n}'**
  String summary_segmentLabel(int n);

  /// No description provided for @summary_pendingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'{n} segment(s) still analyzing…'**
  String summary_pendingAnalysis(int n);

  /// No description provided for @summary_reRecord.
  ///
  /// In en, this message translates to:
  /// **'Re-record'**
  String get summary_reRecord;

  /// No description provided for @summary_notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded yet'**
  String get summary_notRecorded;

  /// No description provided for @summary_notRecordedShort.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get summary_notRecordedShort;

  /// No description provided for @summary_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get summary_analyzing;

  /// No description provided for @summary_analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed — tap Re-record to retry'**
  String get summary_analysisFailed;

  /// No description provided for @summary_youSaid.
  ///
  /// In en, this message translates to:
  /// **'You said'**
  String get summary_youSaid;

  /// No description provided for @summary_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get summary_error;

  /// No description provided for @summary_reviewShort.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get summary_reviewShort;

  /// No description provided for @summary_stopRecord.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get summary_stopRecord;

  /// No description provided for @profile_gallery.
  ///
  /// In en, this message translates to:
  /// **'Select an image from your gallery'**
  String get profile_gallery;

  /// No description provided for @profile_google.
  ///
  /// In en, this message translates to:
  /// **'Use a Google profile picture'**
  String get profile_google;

  /// No description provided for @profile_facebook.
  ///
  /// In en, this message translates to:
  /// **'Use a Facebook profile picture'**
  String get profile_facebook;

  /// No description provided for @math_simulation_scanBtn.
  ///
  /// In en, this message translates to:
  /// **'Scan Answer Sheet'**
  String get math_simulation_scanBtn;

  /// No description provided for @math_simulation_manualCheckBtn.
  ///
  /// In en, this message translates to:
  /// **'Manual Grading (No Camera)'**
  String get math_simulation_manualCheckBtn;

  /// No description provided for @math_simulation_retakeBtn.
  ///
  /// In en, this message translates to:
  /// **'Retake Answer Sheet Photo'**
  String get math_simulation_retakeBtn;

  /// No description provided for @math_simulation_detectedHeader.
  ///
  /// In en, this message translates to:
  /// **'Detected all {count} answers'**
  String math_simulation_detectedHeader(int count);

  /// No description provided for @math_simulation_detectedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap pencil icon to edit if AI conversion is inaccurate'**
  String get math_simulation_detectedHint;

  /// No description provided for @math_simulation_sectionTitle.
  ///
  /// In en, this message translates to:
  /// **'DETECTED ANSWERS'**
  String get math_simulation_sectionTitle;

  /// No description provided for @math_simulation_ocrLabel.
  ///
  /// In en, this message translates to:
  /// **'Scanned Answer: '**
  String get math_simulation_ocrLabel;

  /// No description provided for @math_simulation_noData.
  ///
  /// In en, this message translates to:
  /// **'No scan data (Manual grade)'**
  String get math_simulation_noData;

  /// No description provided for @math_simulation_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Answer for Question {index}'**
  String math_simulation_editTitle(int index);

  /// No description provided for @math_simulation_editHint.
  ///
  /// In en, this message translates to:
  /// **'Type correct mathematical answer...'**
  String get math_simulation_editHint;

  /// No description provided for @math_simulation_questionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Question: {question}'**
  String math_simulation_questionPrefix(String question);

  /// No description provided for @math_simulation_correctAnswerPrefix.
  ///
  /// In en, this message translates to:
  /// **'Expected Answer: {answer}'**
  String math_simulation_correctAnswerPrefix(String answer);

  /// No description provided for @math_simulation_prevBtn.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS'**
  String get math_simulation_prevBtn;

  /// No description provided for @math_simulation_nextBtn.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get math_simulation_nextBtn;

  /// No description provided for @sing_languageBadge.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sing_languageBadge;

  /// No description provided for @sing_heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Sing the song,\nwin the stars!'**
  String get sing_heroTitle;

  /// No description provided for @sing_selectOurSongs.
  ///
  /// In en, this message translates to:
  /// **'Choose Our Songs'**
  String get sing_selectOurSongs;

  /// No description provided for @sing_readyToPlay.
  ///
  /// In en, this message translates to:
  /// **'Ready to play'**
  String get sing_readyToPlay;

  /// No description provided for @sing_createOwnSong.
  ///
  /// In en, this message translates to:
  /// **'Create Your Own'**
  String get sing_createOwnSong;

  /// No description provided for @sing_wordsOrSentences.
  ///
  /// In en, this message translates to:
  /// **'Words / Sentences'**
  String get sing_wordsOrSentences;

  /// No description provided for @sing_chooseSong.
  ///
  /// In en, this message translates to:
  /// **'Choose Song'**
  String get sing_chooseSong;

  /// No description provided for @sing_singingChildren.
  ///
  /// In en, this message translates to:
  /// **'Children singing together ({count})'**
  String sing_singingChildren(int count);

  /// No description provided for @sing_tapAddChild.
  ///
  /// In en, this message translates to:
  /// **'Tap here to add children'**
  String get sing_tapAddChild;

  /// No description provided for @sing_childrenAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} more child(ren)'**
  String sing_childrenAdded(int count);

  /// No description provided for @sing_startSinging.
  ///
  /// In en, this message translates to:
  /// **'START SINGING'**
  String get sing_startSinging;

  /// No description provided for @sing_noSongs.
  ///
  /// In en, this message translates to:
  /// **'No songs are available right now'**
  String get sing_noSongs;

  /// No description provided for @sing_familySongTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Family Memory Song'**
  String get sing_familySongTitle;

  /// No description provided for @sing_familySongSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter something your child should remember and turn it into a song'**
  String get sing_familySongSubtitle;

  /// No description provided for @sing_trainingType.
  ///
  /// In en, this message translates to:
  /// **'What would you like to practice?'**
  String get sing_trainingType;

  /// No description provided for @sing_vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get sing_vocabulary;

  /// No description provided for @sing_sentence.
  ///
  /// In en, this message translates to:
  /// **'Sentence'**
  String get sing_sentence;

  /// No description provided for @sing_vocabularyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Words for your child to remember'**
  String get sing_vocabularyPrompt;

  /// No description provided for @sing_sentencePrompt.
  ///
  /// In en, this message translates to:
  /// **'Sentences for your child to remember'**
  String get sing_sentencePrompt;

  /// No description provided for @sing_vocabularyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. apple, banana, orange, happy'**
  String get sing_vocabularyHint;

  /// No description provided for @sing_sentenceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I brush my teeth every morning.'**
  String get sing_sentenceHint;

  /// No description provided for @sing_musicStyle.
  ///
  /// In en, this message translates to:
  /// **'Music Style'**
  String get sing_musicStyle;

  /// No description provided for @sing_styleKids.
  ///
  /// In en, this message translates to:
  /// **'Fun Kids Song'**
  String get sing_styleKids;

  /// No description provided for @sing_styleDance.
  ///
  /// In en, this message translates to:
  /// **'Dance Pop'**
  String get sing_styleDance;

  /// No description provided for @sing_styleWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm Slow Song'**
  String get sing_styleWarm;

  /// No description provided for @sing_styleHipHop.
  ///
  /// In en, this message translates to:
  /// **'Kids Hip-Hop'**
  String get sing_styleHipHop;

  /// No description provided for @sing_uiOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'The interface is ready. Song generation will be connected in the next step.'**
  String get sing_uiOnlyNotice;

  /// No description provided for @sing_createSongButton.
  ///
  /// In en, this message translates to:
  /// **'Create Song from This Content'**
  String get sing_createSongButton;

  /// No description provided for @sing_showChords.
  ///
  /// In en, this message translates to:
  /// **'Show Parent Guitar Chords'**
  String get sing_showChords;

  /// No description provided for @sing_hideChords.
  ///
  /// In en, this message translates to:
  /// **'Hide Guitar Chords'**
  String get sing_hideChords;

  /// No description provided for @sing_chordsShown.
  ///
  /// In en, this message translates to:
  /// **'Guitar chord mode is on'**
  String get sing_chordsShown;

  /// No description provided for @sing_chordsHidden.
  ///
  /// In en, this message translates to:
  /// **'Guitar chords are hidden'**
  String get sing_chordsHidden;

  /// No description provided for @sing_videoSyncHint.
  ///
  /// In en, this message translates to:
  /// **'The dance video plays with the song'**
  String get sing_videoSyncHint;

  /// No description provided for @sing_hideVideo.
  ///
  /// In en, this message translates to:
  /// **'Hide dance video'**
  String get sing_hideVideo;

  /// No description provided for @sing_showVideo.
  ///
  /// In en, this message translates to:
  /// **'Show dance video'**
  String get sing_showVideo;

  /// No description provided for @sing_retryVideo.
  ///
  /// In en, this message translates to:
  /// **'Retry video'**
  String get sing_retryVideo;

  /// No description provided for @sing_evidenceAttached.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached'**
  String get sing_evidenceAttached;

  /// No description provided for @sing_captureEvidence.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or record evidence video'**
  String get sing_captureEvidence;

  /// No description provided for @sing_attached.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get sing_attached;

  /// No description provided for @sing_recordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get sing_recordVideo;

  /// No description provided for @sing_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get sing_takePhoto;

  /// No description provided for @sing_openVideo.
  ///
  /// In en, this message translates to:
  /// **'Open Video'**
  String get sing_openVideo;

  /// No description provided for @sing_songVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Song Vocabulary:'**
  String get sing_songVocabulary;

  /// No description provided for @sing_pronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation: {value}'**
  String sing_pronunciation(String value);

  /// No description provided for @sing_translation.
  ///
  /// In en, this message translates to:
  /// **'Meaning: {value}'**
  String sing_translation(String value);

  /// No description provided for @sing_cameraPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the camera...'**
  String get sing_cameraPreparing;

  /// No description provided for @sing_cameraRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording video with the song...'**
  String get sing_cameraRecording;

  /// No description provided for @sing_hubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bilingual songs with a guitar chord mode for parents'**
  String get sing_hubSubtitle;

  /// No description provided for @sing_evaluationTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluate Sing Together'**
  String get sing_evaluationTitle;

  /// No description provided for @sing_selectMediaSource.
  ///
  /// In en, this message translates to:
  /// **'Select {media} source'**
  String sing_selectMediaSource(String media);

  /// No description provided for @sing_childFallback.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get sing_childFallback;

  /// No description provided for @sing_saveScoreError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the score: {error}'**
  String sing_saveScoreError(String error);

  /// No description provided for @sing_scoreChild.
  ///
  /// In en, this message translates to:
  /// **'Score {name}'**
  String sing_scoreChild(String name);

  /// No description provided for @sing_scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score (0–100)'**
  String get sing_scoreLabel;

  /// No description provided for @sing_duration.
  ///
  /// In en, this message translates to:
  /// **'Singing time: {minutes} min {seconds} sec'**
  String sing_duration(int minutes, int seconds);

  /// No description provided for @sing_imageVideoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Photo / Video Evidence'**
  String get sing_imageVideoEvidence;

  /// No description provided for @sing_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get sing_change;

  /// No description provided for @sing_watchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch Video 🎥'**
  String get sing_watchVideo;

  /// No description provided for @sing_evaluateChildren.
  ///
  /// In en, this message translates to:
  /// **'Evaluate Children ({count})'**
  String sing_evaluateChildren(int count);

  /// No description provided for @sing_notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional Comments'**
  String get sing_notesTitle;

  /// No description provided for @sing_notesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. sang clearly and pronounced the vocabulary correctly...'**
  String get sing_notesHint;

  /// No description provided for @sing_savingScore.
  ///
  /// In en, this message translates to:
  /// **'Saving score...'**
  String get sing_savingScore;

  /// No description provided for @sing_saveScore.
  ///
  /// In en, this message translates to:
  /// **'Save Singing Score'**
  String get sing_saveScore;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get common_pleaseWait;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_attachmentError.
  ///
  /// In en, this message translates to:
  /// **'Could not attach media: {error}'**
  String common_attachmentError(String error);

  /// No description provided for @languageList_loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load activities: {error}'**
  String languageList_loadError(String error);

  /// No description provided for @languageList_empty.
  ///
  /// In en, this message translates to:
  /// **'No activities in this category yet'**
  String get languageList_empty;

  /// No description provided for @dynamic_listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get dynamic_listening;

  /// No description provided for @dynamic_holdToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Hold to speak'**
  String get dynamic_holdToSpeak;

  /// No description provided for @dynamic_greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get dynamic_greatJob;

  /// No description provided for @dynamic_niceTry.
  ///
  /// In en, this message translates to:
  /// **'Nice try!'**
  String get dynamic_niceTry;

  /// No description provided for @disclaimer_title.
  ///
  /// In en, this message translates to:
  /// **'Software Terms of Use'**
  String get disclaimer_title;

  /// No description provided for @disclaimer_acceptCheck.
  ///
  /// In en, this message translates to:
  /// **'I have read, understood, and accepted these terms'**
  String get disclaimer_acceptCheck;

  /// No description provided for @disclaimer_acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept and Continue'**
  String get disclaimer_acceptButton;

  /// No description provided for @disclaimer_intro.
  ///
  /// In en, this message translates to:
  /// **'Skill Wallet Kizuna was developed for the 28th National Software Contest (NSC 2026) to support children\'s learning and skill development through family activities.'**
  String get disclaimer_intro;

  /// No description provided for @disclaimer_developers.
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get disclaimer_developers;

  /// No description provided for @disclaimer_advisor.
  ///
  /// In en, this message translates to:
  /// **'Advisor'**
  String get disclaimer_advisor;

  /// No description provided for @disclaimer_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get disclaimer_terms;

  /// No description provided for @disclaimer_license.
  ///
  /// In en, this message translates to:
  /// **'The intellectual property belongs to the developers. The developers permit NSTDA to distribute this software ‘as is’ for temporary, non-exclusive, educational or personal non-commercial use without charge.'**
  String get disclaimer_license;

  /// No description provided for @disclaimer_liability.
  ///
  /// In en, this message translates to:
  /// **'NSTDA and the developers are not liable for loss, damage, errors, software performance, or consequences related to its use. Users are responsible for operation and maintenance.'**
  String get disclaimer_liability;

  /// No description provided for @daily_singTogether.
  ///
  /// In en, this message translates to:
  /// **'Sing Together'**
  String get daily_singTogether;

  /// No description provided for @createActivity_physicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Physical Activity'**
  String get createActivity_physicalTitle;

  /// No description provided for @createActivity_calculateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Calculation Activity'**
  String get createActivity_calculateTitle;

  /// No description provided for @createActivity_mathTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Math Problems Activity'**
  String get createActivity_mathTitle;

  /// No description provided for @createActivity_voiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Voice Quest'**
  String get createActivity_voiceTitle;

  /// No description provided for @createActivity_spaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Space Adventure'**
  String get createActivity_spaceTitle;

  /// No description provided for @createActivity_maxScoreRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the maximum score'**
  String get createActivity_maxScoreRequired;

  /// No description provided for @createActivity_timeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the time limit'**
  String get createActivity_timeRequired;

  /// No description provided for @createActivity_itemScoreRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the score per item'**
  String get createActivity_itemScoreRequired;

  /// No description provided for @createActivity_wordCategory.
  ///
  /// In en, this message translates to:
  /// **'Word Category'**
  String get createActivity_wordCategory;

  /// No description provided for @createActivity_timeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time Limit (Seconds)'**
  String get createActivity_timeLimit;

  /// No description provided for @createActivity_scorePerItem.
  ///
  /// In en, this message translates to:
  /// **'Score Per Detected Item'**
  String get createActivity_scorePerItem;

  /// No description provided for @wordCategory_animals.
  ///
  /// In en, this message translates to:
  /// **'🦁 Animals'**
  String get wordCategory_animals;

  /// No description provided for @wordCategory_food.
  ///
  /// In en, this message translates to:
  /// **'🍎 Food'**
  String get wordCategory_food;

  /// No description provided for @wordCategory_vehicles.
  ///
  /// In en, this message translates to:
  /// **'🚀 Vehicles'**
  String get wordCategory_vehicles;

  /// No description provided for @wordCategory_nature.
  ///
  /// In en, this message translates to:
  /// **'🌈 Nature'**
  String get wordCategory_nature;

  /// No description provided for @wordCategory_bedroom.
  ///
  /// In en, this message translates to:
  /// **'🛏️ Bedroom'**
  String get wordCategory_bedroom;

  /// No description provided for @wordCategory_school.
  ///
  /// In en, this message translates to:
  /// **'🎒 School'**
  String get wordCategory_school;

  /// No description provided for @disclaimer_developer1.
  ///
  /// In en, this message translates to:
  /// **'Mr. Kanok Klinsuwan'**
  String get disclaimer_developer1;

  /// No description provided for @disclaimer_developer2.
  ///
  /// In en, this message translates to:
  /// **'Mr. Podjanan Osatanan'**
  String get disclaimer_developer2;

  /// No description provided for @disclaimer_developer3.
  ///
  /// In en, this message translates to:
  /// **'Mr. Nawapon Kitinanprakorn'**
  String get disclaimer_developer3;

  /// No description provided for @disclaimer_advisorName.
  ///
  /// In en, this message translates to:
  /// **'Asst. Prof. Dr. Suwatchai Kamonsantiroj'**
  String get disclaimer_advisorName;

  /// No description provided for @math_scanCorrect.
  ///
  /// In en, this message translates to:
  /// **'Question {index}: detected “{text}” (correct ✓)'**
  String math_scanCorrect(int index, String text);

  /// No description provided for @math_scanIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Question {index}: detected “{text}” (does not match)'**
  String math_scanIncorrect(int index, String text);

  /// No description provided for @math_noRecognition.
  ///
  /// In en, this message translates to:
  /// **'No result was detected from the image'**
  String get math_noRecognition;

  /// No description provided for @math_scanQuestionError.
  ///
  /// In en, this message translates to:
  /// **'Could not scan question {index}: {error}'**
  String math_scanQuestionError(int index, String error);

  /// No description provided for @math_noAnswerFound.
  ///
  /// In en, this message translates to:
  /// **'No answer found'**
  String get math_noAnswerFound;

  /// No description provided for @math_invalidServerResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an invalid response'**
  String get math_invalidServerResponse;

  /// No description provided for @math_scanError.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String math_scanError(String error);

  /// No description provided for @math_submitError.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String math_submitError(String error);

  /// No description provided for @math_scanResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer Scan Results'**
  String get math_scanResultTitle;

  /// No description provided for @math_activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Math Scenario Activity'**
  String get math_activityTitle;

  /// No description provided for @math_exitTvMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Smart TV Mode'**
  String get math_exitTvMode;

  /// No description provided for @math_questionImage.
  ///
  /// In en, this message translates to:
  /// **'Question {index} image'**
  String math_questionImage(int index);

  /// No description provided for @math_swipeNextImage.
  ///
  /// In en, this message translates to:
  /// **'Swipe to view the next image'**
  String get math_swipeNextImage;

  /// No description provided for @math_end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get math_end;

  /// No description provided for @math_noImage.
  ///
  /// In en, this message translates to:
  /// **'No image is available for this question'**
  String get math_noImage;

  /// No description provided for @math_activityDetails.
  ///
  /// In en, this message translates to:
  /// **'Activity Details'**
  String get math_activityDetails;

  /// No description provided for @math_defaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Practice analytical thinking and solve math problems from real-world images. Write each answer on paper before scanning.'**
  String get math_defaultDescription;

  /// No description provided for @math_paperInstruction.
  ///
  /// In en, this message translates to:
  /// **'Prepare paper and a pencil. Write each number clearly so the camera can scan it.'**
  String get math_paperInstruction;

  /// No description provided for @math_questionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String math_questionProgress(int current, int total);

  /// No description provided for @math_proposition.
  ///
  /// In en, this message translates to:
  /// **'PROBLEM SCENARIO'**
  String get math_proposition;

  /// No description provided for @math_reviewAll.
  ///
  /// In en, this message translates to:
  /// **'Review All Results'**
  String get math_reviewAll;

  /// No description provided for @math_cameraCheck.
  ///
  /// In en, this message translates to:
  /// **'Check with Camera (Question {index})'**
  String math_cameraCheck(int index);

  /// No description provided for @math_readingHandwriting.
  ///
  /// In en, this message translates to:
  /// **'Reading handwriting from the photo...'**
  String get math_readingHandwriting;

  /// No description provided for @math_readCorrect.
  ///
  /// In en, this message translates to:
  /// **'Detected “{text}” (correct ✓)'**
  String math_readCorrect(String text);

  /// No description provided for @math_readIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Detected “{text}” (does not match)'**
  String math_readIncorrect(String text);

  /// No description provided for @math_takePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Photograph the handwritten answer for this question'**
  String get math_takePhotoHint;

  /// No description provided for @math_thisQuestionImage.
  ///
  /// In en, this message translates to:
  /// **'This Question\'s Image'**
  String get math_thisQuestionImage;

  /// No description provided for @math_readingAi.
  ///
  /// In en, this message translates to:
  /// **'AI is reading the handwriting...'**
  String get math_readingAi;

  /// No description provided for @math_retakeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Retake This Question'**
  String get math_retakeQuestion;

  /// No description provided for @math_scanQuestion.
  ///
  /// In en, this message translates to:
  /// **'Take Photo / Scan This Question'**
  String get math_scanQuestion;

  /// No description provided for @math_editNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Number'**
  String get math_editNumber;

  /// No description provided for @math_readingAll.
  ///
  /// In en, this message translates to:
  /// **'Reading Answers from the Image'**
  String get math_readingAll;

  /// No description provided for @math_waitFindingNumbers.
  ///
  /// In en, this message translates to:
  /// **'Please wait while the system finds all numbers'**
  String get math_waitFindingNumbers;

  /// No description provided for @math_checkAll.
  ///
  /// In en, this message translates to:
  /// **'Check All Answers'**
  String get math_checkAll;

  /// No description provided for @math_reviewBeforeFinish.
  ///
  /// In en, this message translates to:
  /// **'Review and edit the results before finishing'**
  String get math_reviewBeforeFinish;

  /// No description provided for @math_answerList.
  ///
  /// In en, this message translates to:
  /// **'Answer List'**
  String get math_answerList;

  /// No description provided for @math_solutionValue.
  ///
  /// In en, this message translates to:
  /// **'Solution: {value}'**
  String math_solutionValue(String value);

  /// No description provided for @math_noAnswerDetected.
  ///
  /// In en, this message translates to:
  /// **'No answer detected'**
  String get math_noAnswerDetected;

  /// No description provided for @math_rescan.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get math_rescan;

  /// No description provided for @math_wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well Done!'**
  String get math_wellDone;

  /// No description provided for @math_rewardSaved.
  ///
  /// In en, this message translates to:
  /// **'Your score and reward points have been saved'**
  String get math_rewardSaved;

  /// No description provided for @history_redeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed {name}'**
  String history_redeemed(String name);

  /// No description provided for @history_rewardFallback.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get history_rewardFallback;

  /// No description provided for @spaceScan_pickerError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open image picker: {error}'**
  String spaceScan_pickerError(String error);

  /// No description provided for @spaceScan_failed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed.'**
  String get spaceScan_failed;

  /// No description provided for @spaceScan_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String spaceScan_reason(String reason);

  /// No description provided for @spaceScan_selectSource.
  ///
  /// In en, this message translates to:
  /// **'Select image source'**
  String get spaceScan_selectSource;

  /// No description provided for @spaceScan_scanFirst.
  ///
  /// In en, this message translates to:
  /// **'Please scan your room to find adventure objects first!'**
  String get spaceScan_scanFirst;

  /// No description provided for @spaceScan_deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item?'**
  String get spaceScan_deleteItem;

  /// No description provided for @spaceScan_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove “{item}” from this quest?'**
  String spaceScan_deleteConfirm(String item);

  /// No description provided for @spaceScan_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get spaceScan_delete;

  /// No description provided for @spaceScan_noTargets.
  ///
  /// In en, this message translates to:
  /// **'This area does not have any target items yet.'**
  String get spaceScan_noTargets;

  /// No description provided for @spaceScan_choosePreset.
  ///
  /// In en, this message translates to:
  /// **'Choose preset area'**
  String get spaceScan_choosePreset;

  /// No description provided for @spaceScan_presetDescription.
  ///
  /// In en, this message translates to:
  /// **'Use target items managed in Space Adventure CMS.'**
  String get spaceScan_presetDescription;

  /// No description provided for @spaceScan_noPresets.
  ///
  /// In en, this message translates to:
  /// **'No preset areas are available yet.\nPlease add one in Space Adventure CMS.'**
  String get spaceScan_noPresets;

  /// No description provided for @spaceScan_phase.
  ///
  /// In en, this message translates to:
  /// **'Phase 1: Room scan'**
  String get spaceScan_phase;

  /// No description provided for @spaceScan_intro.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your room to find quest items.'**
  String get spaceScan_intro;

  /// No description provided for @spaceScan_usePreset.
  ///
  /// In en, this message translates to:
  /// **'Use preset'**
  String get spaceScan_usePreset;

  /// No description provided for @spaceScan_cmsItems.
  ///
  /// In en, this message translates to:
  /// **'CMS item list'**
  String get spaceScan_cmsItems;

  /// No description provided for @spaceScan_scanRoom.
  ///
  /// In en, this message translates to:
  /// **'Scan room'**
  String get spaceScan_scanRoom;

  /// No description provided for @spaceScan_findItems.
  ///
  /// In en, this message translates to:
  /// **'Find items in photo'**
  String get spaceScan_findItems;

  /// No description provided for @spaceScan_tapPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap below to take a photo'**
  String get spaceScan_tapPhoto;

  /// No description provided for @spaceScan_scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for items...'**
  String get spaceScan_scanning;

  /// No description provided for @spaceScan_itemsDetected.
  ///
  /// In en, this message translates to:
  /// **'Items detected:'**
  String get spaceScan_itemsDetected;

  /// No description provided for @spaceScan_startQuest.
  ///
  /// In en, this message translates to:
  /// **'Start quest'**
  String get spaceScan_startQuest;

  /// No description provided for @spaceScan_rescan.
  ///
  /// In en, this message translates to:
  /// **'Re-scan'**
  String get spaceScan_rescan;

  /// No description provided for @dynamic_languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get dynamic_languageTitle;

  /// No description provided for @dynamic_tagline.
  ///
  /// In en, this message translates to:
  /// **'Say the word,\nwin the stars!'**
  String get dynamic_tagline;

  /// No description provided for @dynamic_chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose Category'**
  String get dynamic_chooseCategory;

  /// No description provided for @dynamic_todayGoal.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S GOAL'**
  String get dynamic_todayGoal;

  /// No description provided for @dynamic_startQuest.
  ///
  /// In en, this message translates to:
  /// **'Start Quest'**
  String get dynamic_startQuest;

  /// No description provided for @dynamic_exitTvMode.
  ///
  /// In en, this message translates to:
  /// **'Exit TV Mode'**
  String get dynamic_exitTvMode;

  /// No description provided for @dynamic_tvMode.
  ///
  /// In en, this message translates to:
  /// **'TV Mode'**
  String get dynamic_tvMode;

  /// No description provided for @dynamic_listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get dynamic_listen;

  /// No description provided for @dynamic_progress.
  ///
  /// In en, this message translates to:
  /// **'Word {current} of {total}'**
  String dynamic_progress(int current, int total);

  /// No description provided for @dynamic_sayWord.
  ///
  /// In en, this message translates to:
  /// **'Say the word:'**
  String get dynamic_sayWord;

  /// No description provided for @dynamic_meaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning: {meaning}'**
  String dynamic_meaning(String meaning);

  /// No description provided for @dynamic_listenWord.
  ///
  /// In en, this message translates to:
  /// **'Listen: {word}'**
  String dynamic_listenWord(String word);

  /// No description provided for @dynamic_evaluating.
  ///
  /// In en, this message translates to:
  /// **'Evaluating your voice...'**
  String get dynamic_evaluating;

  /// No description provided for @dynamic_speakInstruction.
  ///
  /// In en, this message translates to:
  /// **'Press and hold while speaking. Release when done.'**
  String get dynamic_speakInstruction;

  /// No description provided for @dynamic_youSaid.
  ///
  /// In en, this message translates to:
  /// **'YOU SAID:'**
  String get dynamic_youSaid;

  /// No description provided for @dynamic_targetWord.
  ///
  /// In en, this message translates to:
  /// **'Target word: {word}'**
  String dynamic_targetWord(String word);

  /// No description provided for @dynamic_listenVoice.
  ///
  /// In en, this message translates to:
  /// **'Listen to your voice'**
  String get dynamic_listenVoice;

  /// No description provided for @dynamic_speakAgain.
  ///
  /// In en, this message translates to:
  /// **'Speak Again'**
  String get dynamic_speakAgain;

  /// No description provided for @dynamic_questComplete.
  ///
  /// In en, this message translates to:
  /// **'Quest Complete!'**
  String get dynamic_questComplete;

  /// No description provided for @dynamic_totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get dynamic_totalScore;

  /// No description provided for @dynamic_playRecordingError.
  ///
  /// In en, this message translates to:
  /// **'Cannot play this recording.'**
  String get dynamic_playRecordingError;

  /// No description provided for @dynamic_micPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied. Please allow mic access!'**
  String get dynamic_micPermission;

  /// No description provided for @dynamic_noSpeech.
  ///
  /// In en, this message translates to:
  /// **'No speech heard. Hold the mic and speak clearly!'**
  String get dynamic_noSpeech;

  /// No description provided for @spaceQuest_timeout.
  ///
  /// In en, this message translates to:
  /// **'Space time warp! Time ran out!'**
  String get spaceQuest_timeout;

  /// No description provided for @spaceQuest_verifyError.
  ///
  /// In en, this message translates to:
  /// **'Verification error, please try again!'**
  String get spaceQuest_verifyError;

  /// No description provided for @spaceQuest_objectHunter.
  ///
  /// In en, this message translates to:
  /// **'Object Hunter'**
  String get spaceQuest_objectHunter;

  /// No description provided for @spaceQuest_score.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String spaceQuest_score(int score);

  /// No description provided for @spaceQuest_mission.
  ///
  /// In en, this message translates to:
  /// **'SPACE MISSION QUEST {current}/{total}'**
  String spaceQuest_mission(int current, int total);

  /// No description provided for @spaceQuest_capture.
  ///
  /// In en, this message translates to:
  /// **'Capture the item'**
  String get spaceQuest_capture;

  /// No description provided for @spaceQuest_findTake.
  ///
  /// In en, this message translates to:
  /// **'Find and take a photo of the item'**
  String get spaceQuest_findTake;

  /// No description provided for @spaceQuest_verify.
  ///
  /// In en, this message translates to:
  /// **'Verify match'**
  String get spaceQuest_verify;

  /// No description provided for @spaceQuest_selectChild.
  ///
  /// In en, this message translates to:
  /// **'Please select a child profile before saving the score.'**
  String get spaceQuest_selectChild;

  /// No description provided for @spaceQuest_shareWeb.
  ///
  /// In en, this message translates to:
  /// **'Sharing is supported on mobile devices. Right-click the image to save on Web!'**
  String get spaceQuest_shareWeb;

  /// No description provided for @spaceQuest_sharePhoto.
  ///
  /// In en, this message translates to:
  /// **'Share photo'**
  String get spaceQuest_sharePhoto;

  /// No description provided for @spaceQuest_recapture.
  ///
  /// In en, this message translates to:
  /// **'Recapture'**
  String get spaceQuest_recapture;

  /// No description provided for @spaceQuest_complete.
  ///
  /// In en, this message translates to:
  /// **'Quest Complete!'**
  String get spaceQuest_complete;

  /// No description provided for @spaceQuest_totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get spaceQuest_totalScore;

  /// No description provided for @addChild_title.
  ///
  /// In en, this message translates to:
  /// **'Add Your Little Adventurer!'**
  String get addChild_title;

  /// No description provided for @addChild_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your child and start building healthy habits together.'**
  String get addChild_subtitle;

  /// No description provided for @addChild_name.
  ///
  /// In en, this message translates to:
  /// **'Your Child Name'**
  String get addChild_name;

  /// No description provided for @addChild_nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pokpong'**
  String get addChild_nameHint;

  /// No description provided for @addChild_birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get addChild_birthDate;

  /// No description provided for @addChild_relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get addChild_relationship;

  /// No description provided for @addChild_mother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get addChild_mother;

  /// No description provided for @addChild_button.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChild_button;

  /// No description provided for @home_welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get home_welcomeBack;

  /// No description provided for @home_whosHere.
  ///
  /// In en, this message translates to:
  /// **'Who\'s here?'**
  String get home_whosHere;

  /// No description provided for @home_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get home_add;

  /// No description provided for @home_rewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Reward points'**
  String get home_rewardPoints;

  /// No description provided for @home_redeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get home_redeem;

  /// No description provided for @home_activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get home_activities;

  /// No description provided for @home_newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get home_newBadge;

  /// No description provided for @home_spaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan your room and find hidden items!'**
  String get home_spaceDescription;

  /// No description provided for @common_continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get common_continueGoogle;

  /// No description provided for @common_continueFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get common_continueFacebook;

  /// No description provided for @common_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get common_home;

  /// No description provided for @common_disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get common_disclaimer;

  /// No description provided for @common_login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get common_login;

  /// No description provided for @common_copiedShareText.
  ///
  /// In en, this message translates to:
  /// **'Copied share text'**
  String get common_copiedShareText;

  /// No description provided for @common_copyShareText.
  ///
  /// In en, this message translates to:
  /// **'Copy share text'**
  String get common_copyShareText;

  /// No description provided for @createActivity_choosePrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose the activity you want to create'**
  String get createActivity_choosePrompt;

  /// No description provided for @sing_difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get sing_difficultyEasy;

  /// No description provided for @sing_highScore.
  ///
  /// In en, this message translates to:
  /// **'High: 100'**
  String get sing_highScore;

  /// No description provided for @sing_durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'10 Min'**
  String get sing_durationMinutes;

  /// No description provided for @dynamic_todayCategory.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S CATEGORY'**
  String get dynamic_todayCategory;

  /// No description provided for @dynamic_speaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get dynamic_speaking;

  /// No description provided for @dynamic_silence.
  ///
  /// In en, this message translates to:
  /// **'(Silence)'**
  String get dynamic_silence;

  /// No description provided for @dynamic_scoreEarned.
  ///
  /// In en, this message translates to:
  /// **'+{score} Score'**
  String dynamic_scoreEarned(int score);

  /// No description provided for @dynamic_perfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect! 🏆'**
  String get dynamic_perfect;

  /// No description provided for @dynamic_voiceMatch.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Voice Match 🎙'**
  String dynamic_voiceMatch(int percent);

  /// No description provided for @dynamic_nextWord.
  ///
  /// In en, this message translates to:
  /// **'Next word'**
  String get dynamic_nextWord;

  /// No description provided for @spaceQuest_findItem.
  ///
  /// In en, this message translates to:
  /// **'FIND ITEM: {item}'**
  String spaceQuest_findItem(String item);

  /// No description provided for @spaceQuest_timeoutReason.
  ///
  /// In en, this message translates to:
  /// **'Time ran out before verification!'**
  String get spaceQuest_timeoutReason;

  /// No description provided for @spaceQuest_scanResults.
  ///
  /// In en, this message translates to:
  /// **'Scan results'**
  String get spaceQuest_scanResults;

  /// No description provided for @spaceQuest_correctMatch.
  ///
  /// In en, this message translates to:
  /// **'CORRECT MATCH'**
  String get spaceQuest_correctMatch;

  /// No description provided for @spaceQuest_mismatch.
  ///
  /// In en, this message translates to:
  /// **'MISMATCH DETECTED'**
  String get spaceQuest_mismatch;

  /// No description provided for @spaceQuest_verifiedTarget.
  ///
  /// In en, this message translates to:
  /// **'Vision AI verified your target: {item}'**
  String spaceQuest_verifiedTarget(String item);

  /// No description provided for @spaceQuest_notMatched.
  ///
  /// In en, this message translates to:
  /// **'This photo does not match {item} yet. Please try again.'**
  String spaceQuest_notMatched(String item);

  /// No description provided for @spaceQuest_scored.
  ///
  /// In en, this message translates to:
  /// **'Scored +{points} points! Current total: {total}'**
  String spaceQuest_scored(int points, int total);

  /// No description provided for @spaceQuest_currentTotal.
  ///
  /// In en, this message translates to:
  /// **'Current total: {total} points'**
  String spaceQuest_currentTotal(int total);

  /// No description provided for @spaceQuest_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving score...'**
  String get spaceQuest_saving;

  /// No description provided for @spaceQuest_next.
  ///
  /// In en, this message translates to:
  /// **'Next quest'**
  String get spaceQuest_next;

  /// No description provided for @home_parentFallback.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get home_parentFallback;

  /// No description provided for @welcome_intro.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started!\nAlready part of our community? Welcome back.\nNew here? Join us to learn and grow together.'**
  String get welcome_intro;

  /// No description provided for @common_shareDownloadImage.
  ///
  /// In en, this message translates to:
  /// **'Share / Download image'**
  String get common_shareDownloadImage;

  /// No description provided for @itemintro_noSegments.
  ///
  /// In en, this message translates to:
  /// **'Error: No segments found for {name}.'**
  String itemintro_noSegments(String name);

  /// No description provided for @record_streamUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Recording stream is not supported in this browser.'**
  String get record_streamUnsupported;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
