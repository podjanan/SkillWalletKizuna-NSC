// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome_playBtn => 'PLAY';

  @override
  String get welcome_signUpBtn => 'SIGN-UP';

  @override
  String get welcome_signInBtn => 'LOG IN';

  @override
  String get home_categoryBtn => 'CATEGORY';

  @override
  String get home_physicalBtn => 'PHYSICAL';

  @override
  String get home_languageBtn => 'LANGUAGE';

  @override
  String get home_calculationBtn => 'CALCULATION';

  @override
  String get home_cannotBtn => 'Cannot load popular activities';

  @override
  String get home_nonewBtn => 'No new activities available';

  @override
  String get home_noChildrenMsg =>
      'No children added yet.\nPlease add a child to start viewing activities.';

  @override
  String get home_switchChild => 'Switch Child';

  @override
  String get draft_bannerTitle => 'Activity in progress';

  @override
  String get draft_bannerResume => 'Continue';

  @override
  String get draft_bannerDiscard => 'Discard';

  @override
  String get draft_discardTitle => 'Discard progress?';

  @override
  String get draft_discardMsg =>
      'Your saved progress for this activity will be deleted.';

  @override
  String get draft_leaveTitle => 'Leave activity?';

  @override
  String get draft_leaveMsg =>
      'Your progress will be saved. You can continue later from the home screen.';

  @override
  String get draft_leaveBtn => 'Save & Leave';

  @override
  String get draft_conflictTitle => 'Active saved progress';

  @override
  String draft_conflictMsg(String name) {
    return 'You have saved progress for \"$name\". Starting a new activity will discard it, or you can cancel and resume.';
  }

  @override
  String get draft_conflictPlay => 'Start New';

  @override
  String get common_discardChanges => 'Discard changes?';

  @override
  String get common_discardMsg => 'Your unsaved changes will be lost.';

  @override
  String get common_discard => 'Discard';

  @override
  String get common_keepEditing => 'Keep Editing';

  @override
  String get home_popularactivityBtn => 'POPULAR ACTIVITIES';

  @override
  String get home_newactivityBtn => 'NEW ACTIVITIES';

  @override
  String get home_viewallBtn => 'View All';

  @override
  String get home_searchBtn => 'SEARCH';

  @override
  String get home_bannerLanguage => 'LANGUAGE TRAINING';

  @override
  String get home_bannerCalculate => 'CALCULATE';

  @override
  String get home_bannerProblems => 'PROBLEMS SOLVE';

  @override
  String get home_filterTitle => 'FILTER ACTIVITIES';

  @override
  String get home_filterCategory => 'CATEGORY';

  @override
  String get home_filterLevel => 'LEVEL';

  @override
  String get home_filterAll => 'ALL';

  @override
  String get home_filterEasy => 'EASY';

  @override
  String get home_filterMedium => 'MEDIUM';

  @override
  String get home_filterHard => 'HARD';

  @override
  String get home_suggested => 'SUGGESTED';

  @override
  String get parentprofile_postBtn => 'POST';

  @override
  String get register_backBtn => 'BACK';

  @override
  String get register_signuptoBtn => 'SIGN-UP TO';

  @override
  String get register_facebookBtn => 'CONTINUE WITH FACEBOOK';

  @override
  String get register_googleBtn => 'CONTINUE WITH GOOGLE';

  @override
  String get register_nextBtn => 'NEXT';

  @override
  String get register_registerBtn => 'REGISTER';

  @override
  String get register_additionalBtn => 'ADDITIONAL INFORMATION';

  @override
  String register_namesurnamechildBtn(Object index) {
    return 'NAME & SURNAME (CHILDREN) $index';
  }

  @override
  String get register_birthdayBtn => 'BIRTHDAY : DD/MM/YYYY';

  @override
  String get register_okBtn => 'OK';

  @override
  String get register_pls => 'Please fill in all the information in the list. ';

  @override
  String get register_finish => 'Successfully registered!';

  @override
  String get register_relation => 'RELATION';

  @override
  String get register_pickbirthday => 'Choose birthday';

  @override
  String get register_Anerroroccurredplstry =>
      'An error occurred. Please try again.';

  @override
  String register_Anerroroccurred(Object index) {
    return 'An error occurred: $index';
  }

  @override
  String register_sus(Object index) {
    return 'Registration successful! Added $index child.';
  }

  @override
  String register_submitterror(Object index) {
    return 'Submit error: $index';
  }

  @override
  String register_requiredinformation(Object index) {
    return 'Please fill in all the required information (name, date of birth, relationship) in the list. $index';
  }

  @override
  String get login_backBtn => 'BACK';

  @override
  String get login_facebookBtn => 'CONTINUE WITH FACEBOOK';

  @override
  String get login_googleBtn => 'CONTINUE WITH GOOGLE';

  @override
  String get login_loading => 'Signing in...';

  @override
  String get login_noAccount => 'No account found. Please register first.';

  @override
  String get login_goToRegister => 'GO TO REGISTER';

  @override
  String get register_loading => 'Registering...';

  @override
  String get register_alreadyExists =>
      'This account is already registered. Please login instead.';

  @override
  String get register_goToLogin => 'GO TO LOGIN';

  @override
  String get auth_termsAgree => 'I have read and agree to the';

  @override
  String get auth_termsOfService => 'Terms of Service';

  @override
  String get auth_privacyPolicy => 'Privacy Policy';

  @override
  String get auth_and => 'and';

  @override
  String get auth_pleaseAgreeTerms =>
      'Please agree to the Terms of Service and Privacy Policy first.';

  @override
  String get auth_loading => 'Signing in...';

  @override
  String get auth_tosDialogMsg =>
      'To ensure things are in your best interests, please review the Terms of Service and then choose to enter.';

  @override
  String get auth_readTos => 'Read TOS';

  @override
  String get auth_enter => 'Enter';

  @override
  String get setting_backBtn => 'BACK';

  @override
  String get setting_settingBtn => 'SETTING';

  @override
  String get setting_personalBtn => 'PERSONAL INFORMATION';

  @override
  String get setting_generalBtn => 'GENERAL';

  @override
  String get setting_profileBtn => 'PROFILE';

  @override
  String get setting_childBtn => 'CHILD';

  @override
  String get setting_notificationBtn => 'NOTIFICATIONS';

  @override
  String get setting_thaiBtn => 'THAI';

  @override
  String get setting_englishBtn => 'ENGLISH';

  @override
  String get setting_logoutBtn => 'LOG OUT';

  @override
  String get setting_logoutTitle => 'Log Out?';

  @override
  String get setting_logoutMsg => 'Are you sure you want to log out?';

  @override
  String get setting_logoutConfirm => 'LOG OUT';

  @override
  String get setting_deleteAccountBtn => 'DELETE ACCOUNT';

  @override
  String get setting_deleteTitle => 'Delete Account?';

  @override
  String get setting_deleteMsg =>
      'This will permanently delete your account and all children data. Your data will be removed within 30 days. This action cannot be undone.';

  @override
  String get setting_deleteConfirm => 'DELETE';

  @override
  String get setting_deleteSuccess => 'Account deleted successfully.';

  @override
  String get setting_deleteError =>
      'Failed to delete account. Please try again.';

  @override
  String get namesetting_changenameBtn => 'CHANGE NAME';

  @override
  String get namesetting_enternewnameBtn => 'ENTER NEW NAME';

  @override
  String get namesetting_hint => 'Type your name...';

  @override
  String get namesetting_saveBtn => 'SAVE';

  @override
  String get profilesetting_nameBtn => 'NAME';

  @override
  String get profilesetting_deleteaccoutBtn => 'DELETE ACCOUNT';

  @override
  String get profileSet_deleteDialogTitle => 'DELETE ACCOUNT?';

  @override
  String get profilesetting_areusureBtn =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get profilesetting_cancelBtn => 'CANCEL';

  @override
  String get profilesetting_deleteBtn => 'DELETE';

  @override
  String get childprofile_mathGame => 'MATH GAME';

  @override
  String get childprofile_workoutGame => 'WORK OUT GAME';

  @override
  String get childsetting_childsettingBtn => 'CHILD SETTING';

  @override
  String get childsetting_scoreBtn => 'SCORE';

  @override
  String get childsetting_viewprofileBtn => 'VIEW PROFILE';

  @override
  String get childsetting_manageBtn => 'MANAGE';

  @override
  String get childgallery_title => 'MY GALLERY';

  @override
  String get childgallery_empty => 'NO POSTS YET';

  @override
  String get history_timesSuffix => 'TIMES';

  @override
  String get result_title => 'PLAYING RESULT';

  @override
  String get result_timeUsedTitle => 'TIME USED';

  @override
  String get redemption_playBtn => 'PLAY';

  @override
  String get redemption_rewardIceCream => 'ICE CREAM';

  @override
  String get redemption_rewardPlaytime => '1 HR PLAYTIME';

  @override
  String get redemption_rewardToy => 'NEW TOY';

  @override
  String get redemption_rewardStickers => 'STICKERS';

  @override
  String get redemption_historyPlayedDefault => 'Played Ping Pong';

  @override
  String get redemption_historyRedeemedDefault => 'Redeemed Ice Cream';

  @override
  String get dialog_deleteTitle => 'Delete Profile?';

  @override
  String get dialog_deleteContent =>
      'Are you sure you want to delete this profile? This action cannot be undone.';

  @override
  String get dialog_confirmDelete => 'DELETE';

  @override
  String get dialog_cancel => 'CANCEL';

  @override
  String get dialog_saveSuccess => 'Saved successfully!';

  @override
  String get notificationsetting_notificationBtn => 'NOTIFICATIONS';

  @override
  String get notificationsetting_allnotificationBtn => 'ALL NOTIFICATIONS';

  @override
  String get notificationsetting_postBtn => 'POST';

  @override
  String get notificationsetting_likeBtn => 'LIKE';

  @override
  String get notificationsetting_commentBtn => 'COMMENT';

  @override
  String get videodetail_activitynameBtn => 'ACTIVITY NAME';

  @override
  String get videodetail_nameBtn => 'name';

  @override
  String get videodetail_DescriptionBtn => 'DESCRIPTION';

  @override
  String get videodetail_descriptionBtn => 'description';

  @override
  String get videodetail_howtoplayBtn => 'HOW TO PLAY / INSTRUCTIONS:';

  @override
  String get videodetail_contentBtn => 'content';

  @override
  String get videodetail_startBtn => 'START';

  @override
  String get videodetail_addBtn => 'ADD';

  @override
  String get videodetail_videoNotAvailable =>
      'Video Not Available (HTML Content Missing)';

  @override
  String get videodetail_activityNameLabel => 'ACTIVITY NAME:';

  @override
  String get videodetail_descriptionLabel => 'DESCRIPTION:';

  @override
  String get videodetail_howToPlayLabel => 'HOW TO PLAY / INSTRUCTIONS:';

  @override
  String get videodetail_categoryPrefix => 'Category: ';

  @override
  String get videodetail_difficultyPrefix => 'Difficulty: ';

  @override
  String get videodetail_maxScorePrefix => 'Max Score: ';

  @override
  String get addchild_namesurnameBtn => 'NAME & SURNAME (CHILDREN)';

  @override
  String get addchild_errorName => 'Please enter a name';

  @override
  String get addchild_birthdayBtn => 'BIRTHDAY : DD/MM/YYYY';

  @override
  String get addchild_okBtn => 'OK';

  @override
  String get addchild_logoutTitle => 'Log out?';

  @override
  String get addchild_logoutMsg =>
      'Please add at least one child to use the app. Are you sure you want to log out?';

  @override
  String get addchild_errorRequiredFields =>
      'Please fill in all required fields (name, birthday, relationship).';

  @override
  String get childnamesetting_editnameBtn => 'EDIT NAME';

  @override
  String get childnamesetting_saveBtn => 'SAVE';

  @override
  String get managechild_manageprofileBtn => 'MANAGE PROFILE';

  @override
  String get managechild_nameBtn => 'NAME';

  @override
  String get managechild_medalsandredemptionBtn => 'MEDALS & REDEMPTION';

  @override
  String get managechild_deleteprofileBtn => 'DELETE PROFILE';

  @override
  String get dairyactivity_playhistoryBtn => 'PLAYING HISTORY';

  @override
  String get dairyactivity_timeBtn => 'time';

  @override
  String get dairyactivity_medalsBtn => 'medals';

  @override
  String get medalredemption_addrewardBtn => 'ADD AGREEMENT';

  @override
  String get medalredemption_rewardnameBtn => 'Agreement Name';

  @override
  String get medalredemption_costBtn => 'Cost (Points)';

  @override
  String get medalredemption_cancelBtn => 'CANCEL';

  @override
  String get medalredemption_addBtn => 'ADD';

  @override
  String get medalredemption_redemptionBtn => 'AGREEMENTS';

  @override
  String get medalredemption_activitiesBtn => 'ACTIVITIES';

  @override
  String get medalredemption_currentscoreBtn => 'CURRENT SCORE';

  @override
  String get medalredemption_rewardshopBtn => 'AGREEMENTS';

  @override
  String get medalredemption_successfullyBtn => 'Successfully Redeemed';

  @override
  String get agreement_typeTime => 'Time';

  @override
  String get agreement_typeItem => 'Item';

  @override
  String get agreement_typePrivilege => 'Privilege';

  @override
  String get agreement_typeFamily => 'Family';

  @override
  String get agreement_selectType => 'Select Agreement Type';

  @override
  String get agreement_confirmTitle => 'Confirm Agreement';

  @override
  String agreement_confirmMsg(int cost, String name) {
    return 'Use $cost points to redeem \"$name\"?';
  }

  @override
  String get agreement_confirmBtn => 'CONFIRM';

  @override
  String get agreement_sessionActive => 'Session Active';

  @override
  String get agreement_timeRemaining => 'Time Remaining';

  @override
  String get agreement_startTimer => 'START';

  @override
  String get agreement_stopTimer => 'STOP';

  @override
  String get agreement_endSession => 'END SESSION';

  @override
  String get agreement_sessionComplete => 'Session Complete!';

  @override
  String get agreement_behaviorTitle => 'How was the behavior?';

  @override
  String get agreement_behaviorGood => 'Good';

  @override
  String get agreement_behaviorOk => 'OK';

  @override
  String get agreement_behaviorBad => 'Needs Improvement';

  @override
  String agreement_bonusMsg(int points) {
    return 'Bonus: +$points points';
  }

  @override
  String agreement_deductMsg(int points) {
    return 'Deduction: -$points points';
  }

  @override
  String get agreement_noChange => 'No point change';

  @override
  String agreement_notEnoughPoints(int needed) {
    return 'Not enough points! Need $needed more.';
  }

  @override
  String get agreement_durationLabel => 'Duration (minutes)';

  @override
  String get agreement_emptyList => 'No agreements yet';

  @override
  String get agreement_emptyHint => 'Tap + to create a new agreement';

  @override
  String get physical_snackNoEvidence =>
      'Please attach video or image evidence.';

  @override
  String physical_snackInvalidScore(int maxScore) {
    return 'Please set a valid score (1 to $maxScore).';
  }

  @override
  String get physical_dialogSubmitTitle => 'Submission Complete!';

  @override
  String get physical_dialogSubmitContent =>
      'Your evidence has been submitted for approval.';

  @override
  String get physical_dialogOkBtn => 'OK';

  @override
  String physical_snackSubmitError(String error) {
    return 'Submission Error: $error';
  }

  @override
  String get physical_dialogEnterScoreTitle => 'Enter Score';

  @override
  String physical_dialogEnterScoreHint(int maxScore) {
    return 'Enter score (1-$maxScore)';
  }

  @override
  String get physical_dialogCancelBtn => 'Cancel';

  @override
  String physical_snackInvalidInput(int maxScore) {
    return 'Please enter a valid score (0-$maxScore)';
  }

  @override
  String get physical_stopBtn => 'STOP';

  @override
  String get physical_startBtn => 'START';

  @override
  String get physical_takePhotoBtn => 'TAKE PHOTO';

  @override
  String get physical_medalsScoreLabel => 'MEDALS / SCORE';

  @override
  String get physical_diaryLabel => 'DIARY';

  @override
  String get physical_diaryHint => 'Enter notes here...';

  @override
  String get physical_imageEvidenceLabel => 'IMAGE EVIDENCE';

  @override
  String get physical_videoEvidenceLabel => 'VIDEO EVIDENCE';

  @override
  String get physical_timeLabel => 'TIME';

  @override
  String get physical_submittingBtn => 'Submitting...';

  @override
  String get physical_finishBtn => 'FINISH';

  @override
  String get physical_addChildren => 'Add Children';

  @override
  String get physical_addChildrenDesc => 'Select children to play together';

  @override
  String physical_childrenAdded(int count) {
    return '+$count children';
  }

  @override
  String get physical_currentChild => 'Currently playing';

  @override
  String get physical_confirm => 'Confirm';

  @override
  String get languagedetail_titlePrefix => 'LANGUAGE: ';

  @override
  String get languagedetail_categoryPrefix => 'CATEGORY: ';

  @override
  String get languagedetail_activityTitleLabel => 'ACTIVITY TITLE';

  @override
  String get languagedetail_descriptionLabel => 'DESCRIPTION';

  @override
  String get languagedetail_difficultyPrefix => 'Difficulty: ';

  @override
  String get languagedetail_maxScorePrefix => 'Max Score: ';

  @override
  String get languagedetail_startBtn => 'START';

  @override
  String get languagedetail_openInYoutube => 'Open in YouTube (TV)';

  @override
  String get itemintro_recordToEnable => 'Record to enable playback';

  @override
  String get itemintro_listenExampleBtn => 'LISTEN TO EXAMPLE';

  @override
  String get itemintro_practiceNowBtn => 'PRACTICE NOW';

  @override
  String get itemintro_submitBtn => 'SUBMIT';

  @override
  String get itemintro_playsection => 'PLAY SECTION';

  @override
  String get itemintro_record => 'RECORD';

  @override
  String get itemintro_casttotv => 'CAST TO TV';

  @override
  String get itemintro_airplay => 'AIRPLAY';

  @override
  String get itemintro_previous => '< PREVIOUS';

  @override
  String get itemintro_next => 'NEXT >';

  @override
  String get itemintro_finish => 'FINISH >';

  @override
  String get itemintro_Videonotavailable => 'Video not available';

  @override
  String get record_loading => 'Loading...';

  @override
  String get record_finishBtn => 'FINISH';

  @override
  String get record_errorMic => 'Microphone error or permission denied';

  @override
  String get record_statusRecording => 'Recording...';

  @override
  String get record_statusIdle => 'Press mic to record';

  @override
  String get result_activityCompletedDefault => 'ACTIVITY COMPLETED';

  @override
  String get result_greatJobTitle => 'GREAT JOB!';

  @override
  String get result_totalScoreLabel => 'Total Score';

  @override
  String get result_timeSpentLabel => 'Time Spent';

  @override
  String get result_retryBtn => 'RETRY';

  @override
  String get result_backToActivitiesBtn => 'BACK TO ACTIVITIES';

  @override
  String get result_returnHomeBtn => 'RETURN HOME';

  @override
  String result_timeFormat(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String get calculate_title => 'CALCULATE';

  @override
  String get calculate_plusBtn => 'PLUS +';

  @override
  String get calculate_minusBtn => 'MINUS -';

  @override
  String get calculate_multiplyBtn => 'MULTIPLY *';

  @override
  String get calculate_divideBtn => 'DEVIDE /';

  @override
  String get calculate_mixBtn => 'MIX + - * /';

  @override
  String get languagehub_searchHint => 'search...';

  @override
  String get languagehub_trainingTitle => 'LANGUAGE TRAINING';

  @override
  String get languagehub_listeningSpeakingTitle => 'LISTENING AND SPEAKING';

  @override
  String get languagehub_easyBtn => 'EASY';

  @override
  String get languagehub_mediumBtn => 'MEDIUM';

  @override
  String get languagehub_difficultBtn => 'DIFFICULT';

  @override
  String get plus_castToTvBtn => 'CAST TO TV';

  @override
  String get plus_answerBtn => 'ANSWER';

  @override
  String get createpost_sharesus => 'Post shared successfully!';

  @override
  String get createpost_error => 'An error occurred:';

  @override
  String get createpost_newpost => 'New post';

  @override
  String get createpost_share => 'Share';

  @override
  String get createpost_picksomepicture => 'Tap to select a picture';

  @override
  String get createpost_changepic => 'Change picture';

  @override
  String get createpost_writecaption => 'Write a caption...';

  @override
  String get languagelist_snackNotConnected =>
      'This flow is not connected to activities yet.';

  @override
  String get common_categoryLabel => 'Category';

  @override
  String get common_difficultyLabel => 'Difficulty';

  @override
  String get common_maxScoreLabel => 'Max Score';

  @override
  String get common_categoryLanguage => 'Language';

  @override
  String get common_categoryPhysical => 'Physical';

  @override
  String get common_categoryCalculate => 'Calculate';

  @override
  String get common_activityLanguage => 'Language Activity';

  @override
  String get common_activityPhysical => 'Physical Activity';

  @override
  String get common_activityCalculate => 'Calculation Activity';

  @override
  String get common_difficultyEasy => 'Easy';

  @override
  String get common_difficultyMedium => 'Medium';

  @override
  String get common_difficultyHard => 'Hard';

  @override
  String get createActivity_title => 'CREATE ACTIVITY';

  @override
  String get createActivity_selectCategory => 'Select Category';

  @override
  String get createActivity_physical => 'Physical';

  @override
  String get createActivity_calculate => 'Calculate';

  @override
  String get createActivity_name => 'Activity Name';

  @override
  String get createActivity_description => 'Description';

  @override
  String get createActivity_content => 'How to Play / Instructions';

  @override
  String get createActivity_difficulty => 'Difficulty';

  @override
  String get createActivity_maxScore => 'Max Score';

  @override
  String get createActivity_videoUrl => 'Video URL (TikTok)';

  @override
  String get createActivity_addQuestion => 'Add Question';

  @override
  String get createActivity_question => 'Question';

  @override
  String get createActivity_answer => 'Answer';

  @override
  String get createActivity_solution => 'Solution / Explanation';

  @override
  String get createActivity_score => 'Score';

  @override
  String get createActivity_submit => 'CREATE';

  @override
  String get createActivity_success => 'Activity created successfully!';

  @override
  String get createActivity_error => 'Failed to create activity';

  @override
  String get createActivity_nameRequired => 'Please enter an activity name';

  @override
  String get createActivity_contentRequired => 'Please enter instructions';

  @override
  String get createActivity_needQuestions => 'Please add at least one question';

  @override
  String createActivity_questionNo(int index) {
    return 'Question $index';
  }

  @override
  String get createActivity_removeQuestion => 'Remove';

  @override
  String get createActivity_creating => 'Creating...';

  @override
  String get profile_myActivities => 'MY ACTIVITIES';

  @override
  String get profile_noActivities => 'No activities yet';

  @override
  String get profile_editActivity => 'Edit Activity';

  @override
  String get profile_deleteActivity => 'Delete Activity';

  @override
  String profile_deleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get profile_deleteSuccess => 'Activity deleted';

  @override
  String get profile_updateSuccess => 'Activity updated';

  @override
  String get profile_save => 'SAVE';

  @override
  String get profile_manage => 'MANAGE';

  @override
  String get share_title => 'SHARE RESULT';

  @override
  String get share_asImage => 'Image';

  @override
  String get share_asText => 'Text';

  @override
  String get share_greatJob => 'GREAT JOB!';

  @override
  String get share_keepTrying => 'KEEP TRYING!';

  @override
  String share_textTemplate(String activityName, int score, int maxScore) {
    return 'I scored $score/$maxScore on \"$activityName\" in Skill Wallet Kizuna!';
  }

  @override
  String get common_loginFailed => 'Login failed. Please try again.';

  @override
  String common_errorGeneric(String msg) {
    return 'Error: $msg';
  }

  @override
  String get common_error => 'Error';

  @override
  String get common_processing => 'Processing...';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_close => 'Close';

  @override
  String get common_noServer => 'Cannot connect to server';

  @override
  String get audio_tooShort => 'Audio data too short — try again';

  @override
  String get audio_notFound => 'Audio file not found — try again';

  @override
  String get audio_analyseFailed => 'Analysis failed — try again';

  @override
  String get calculate_restartTitle => 'Restart?';

  @override
  String get calculate_restartMsg => 'Time and answers will be reset';

  @override
  String get calculate_restartBtn => 'Restart';

  @override
  String calculate_solutionTitle(int index) {
    return 'Answer #$index';
  }

  @override
  String get calculate_questionLabel => 'Question:';

  @override
  String get calculate_answerLabel => 'Answer:';

  @override
  String get calculate_pressStart => 'Press START button to begin timing';

  @override
  String get calculate_questionsAfterTimer =>
      'Questions will appear after timing completes';

  @override
  String calculate_failedPickFile(String error) {
    return 'Failed to pick file: $error';
  }

  @override
  String get calculate_childIdNotFound =>
      'Child ID not found. Please login again.';

  @override
  String calculate_errorCompleting(String error) {
    return 'Error completing activity: $error';
  }

  @override
  String get itemintro_videoLoading => 'Please wait. Video is loading...';

  @override
  String get itemintro_timingIncomplete =>
      'Timing data for this sentence is incomplete';

  @override
  String itemintro_videoPlayError(String error) {
    return 'Cannot play video: $error';
  }

  @override
  String get itemintro_micPermission => 'Please allow microphone access';

  @override
  String itemintro_recordStartError(String error) {
    return 'Cannot start recording: $error';
  }

  @override
  String get itemintro_recordTooShort =>
      'Recording too short. Please try again';

  @override
  String itemintro_evalResult(int score, String text) {
    return 'Evaluation result: $score% - \"$text\"';
  }

  @override
  String itemintro_questError(String error) {
    return 'Error completing quest: $error';
  }

  @override
  String get itemintro_playbackFailed => 'Failed to play back recording.';

  @override
  String get record_micDenied => 'Microphone permission denied.';

  @override
  String get record_recordingFailed => 'Recording failed.';

  @override
  String get record_playbackFailed => 'Failed to play audio.';

  @override
  String get record_noValidAudio => 'Error: No valid audio recorded.';

  @override
  String record_aiError(String error) {
    return 'AI Error: $error';
  }

  @override
  String get medals_noActivityHistory => 'No activity history';

  @override
  String get medals_noHistory => 'No history';

  @override
  String get post_noComments => 'No comments yet. Be the first!';

  @override
  String get namesetting_saveFailed => 'Cannot save name. Please try again.';

  @override
  String get activityCard_selectChild => 'Please select a child';

  @override
  String get activityCard_selectChildMsg =>
      'You must select a child before playing activities';

  @override
  String get activityCard_goSelect => 'Go select child';

  @override
  String get childsetting_addSuccess => 'Child added successfully';

  @override
  String get childsetting_deleteSuccess => 'Child deleted successfully';

  @override
  String get childsetting_selectSuccess => 'Child selected successfully';

  @override
  String get childsetting_noChildren => 'No children in system';

  @override
  String get childsetting_addChild => 'Add child';

  @override
  String get childsetting_active => 'ACTIVE';

  @override
  String get childsetting_select => 'SELECT';

  @override
  String get common_selectSource => 'Select Source';

  @override
  String get common_camera => 'Camera';

  @override
  String get common_gallery => 'Gallery';

  @override
  String get common_pickFromGallery => 'Pick from gallery';

  @override
  String get common_useGooglePhoto => 'Use Google profile photo';

  @override
  String get common_useFacebookPhoto => 'Use Facebook profile photo';

  @override
  String get common_useOriginalPhoto => 'Use previous profile photo';

  @override
  String get common_uploadPhotoFailed => 'Photo upload failed';

  @override
  String common_photoNotFound(String provider) {
    return 'No profile photo found from $provider';
  }

  @override
  String get common_ok => 'OK';

  @override
  String get common_submit => 'SUBMIT';

  @override
  String get common_addImage => 'Add Image';

  @override
  String get common_addVideo => 'Add Video';

  @override
  String get common_videoAdded => 'Video Added';

  @override
  String get common_image => 'IMAGE';

  @override
  String get common_video => 'VIDEO';

  @override
  String get common_howToPlay => 'HOW TO PLAY';

  @override
  String get common_questions => 'QUESTIONS';

  @override
  String get common_evidence => 'EVIDENCE';

  @override
  String get common_finish => 'FINISH';

  @override
  String get common_start => 'START';

  @override
  String get common_restart => 'RESTART';

  @override
  String get common_done => 'done';

  @override
  String get common_submitting => 'Submitting...';

  @override
  String get common_score => 'Score';

  @override
  String get calculate_noAnswer => 'No answer available';

  @override
  String get calculate_answer => 'ANSWER';

  @override
  String get calculate_answerAgain => 'ANSWER AGAIN';

  @override
  String get calculate_stopBeforeAnswer => 'Stop timer before answering';

  @override
  String calculate_yourAnswer(String answer) {
    return 'Your answer: $answer';
  }

  @override
  String get calculate_typeAnswer => 'Type your answer...';

  @override
  String get calculate_diaryNotes => 'DIARY / NOTES';

  @override
  String get calculate_writeNotes => 'Write your notes here...';

  @override
  String get calculate_noQuestions => 'No questions available';

  @override
  String get calculate_confirmFinishTitle => 'Finish?';

  @override
  String get calculate_confirmFinishMsg =>
      'Are you sure you want to finish? You cannot restart the timer.';

  @override
  String get calculate_descriptionLabel => 'DESCRIPTION';

  @override
  String get calculate_solutionLabel => 'Solution:';

  @override
  String get calculate_correct => 'CORRECT';

  @override
  String get calculate_incorrect => 'INCORRECT';

  @override
  String get record_title => 'RECORD';

  @override
  String itemintro_segmentOf(int current, int total) {
    return 'Segment $current of $total';
  }

  @override
  String get itemintro_speak => 'SPEAK';

  @override
  String get itemintro_point => 'POINT';

  @override
  String get itemintro_completed => 'COMPLETED';

  @override
  String get itemintro_pausePlayback => 'PAUSE PLAYBACK...';

  @override
  String get itemintro_listenRecording => 'LISTEN TO YOUR RECORDING';

  @override
  String get itemintro_recordToPlayback => 'Record to enable playback';

  @override
  String get videodetail_previewNotAvailable => 'Video Preview Not Available';

  @override
  String get videodetail_openInBrowser => 'Open in Browser to Watch';

  @override
  String get videodetail_openTiktok => 'OPEN TIKTOK';

  @override
  String get videodetail_openInTiktokTV => 'Open in TikTok (TV)';

  @override
  String get videodetail_noVideoUrl => 'No video URL available';

  @override
  String get calculate_tvMode => 'TV Mode';

  @override
  String get calculate_tvModeHint => 'Swipe to see next problem';

  @override
  String get calculate_questionsCount => 'questions';

  @override
  String get calculate_tvModeBannerTitle => 'Share to TV';

  @override
  String get calculate_tvModeBannerSub => 'Show problems on big screen';

  @override
  String get languagehub_appTitle => 'KRATON';

  @override
  String get languagehub_fillInBlanksTitle => 'FILL IN THE BLANKS';

  @override
  String get result_resultTitle => 'RESULT';

  @override
  String get result_totalScoreTitle => 'TOTAL SCORE';

  @override
  String get result_keepTryingTitle => 'KEEP TRYING!';

  @override
  String get result_timeSpentPrefix => 'TIME SPENT: ';

  @override
  String get result_playAgainBtn => 'PLAY AGAIN';

  @override
  String get plus_title => 'PLUS +';

  @override
  String get plus_questionTitle => 'QUESTION';

  @override
  String get plus_startBtn => 'START';

  @override
  String get answerplus_title => 'ANSWER PLUS +';

  @override
  String get answerplus_questionLabel => 'QUESTION';

  @override
  String get answerplus_answerLabel => 'ANSWER';

  @override
  String get email_loginTitle => 'Login with Email';

  @override
  String get email_registerTitle => 'Register';

  @override
  String get email_emailHint => 'Email';

  @override
  String get email_passwordHint => 'Password';

  @override
  String get email_nameHint => 'Full Name';

  @override
  String get email_loginBtn => 'LOGIN';

  @override
  String get email_registerBtn => 'REGISTER';

  @override
  String get email_forgotPassword => 'Forgot Password?';

  @override
  String get email_noAccount => 'Don\'t have an account? Register';

  @override
  String get email_hasAccount => 'Already have an account? Login';

  @override
  String get email_resetSent =>
      'Password reset email sent. Please check your inbox.';

  @override
  String get email_passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get email_enterEmail => 'Please enter your email';

  @override
  String get email_enterPassword => 'Please enter your password';

  @override
  String get email_enterName => 'Please enter your name';

  @override
  String get email_forgotTitle => 'Reset Password';

  @override
  String get email_forgotMsg =>
      'Enter your email to receive a password reset link.';

  @override
  String get email_sendReset => 'SEND';

  @override
  String get email_loginWithEmail => 'LOGIN WITH EMAIL';

  @override
  String get email_confirmSent =>
      'Confirmation email sent. Please check your inbox and click the link to verify, then log in.';

  @override
  String get email_confirmPasswordHint => 'Confirm Password';

  @override
  String get email_passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get register_childNameHint => 'First - Last Name';

  @override
  String get register_birthdayHint => 'DD/MM/YYYY';

  @override
  String get relation_label => 'RELATIONSHIP';

  @override
  String get relation_hint => 'Select relationship';

  @override
  String get relation_parent => 'Father/Mother';

  @override
  String get relation_grandparentPaternal =>
      'Grandfather/Grandmother (Father\'s side)';

  @override
  String get relation_grandparentMaternal =>
      'Grandfather/Grandmother (Mother\'s side)';

  @override
  String get relation_auntUncle => 'Aunt/Uncle';

  @override
  String get relation_caregiver => 'Caregiver';

  @override
  String get relation_nanny => 'Nanny/Babysitter';

  @override
  String get activityhistory_selectDate => 'Select date';

  @override
  String activityhistory_times(int count) {
    return '$count times';
  }

  @override
  String get activityhistory_noHistory => 'No activity history';

  @override
  String activityhistory_inCategory(String category) {
    return 'In $category';
  }

  @override
  String get dailyactivity_playingHistory => 'Playing history';

  @override
  String get dailyactivity_noData => 'No data';

  @override
  String get dailyactivity_activity => 'Activity';

  @override
  String get childprofile_language => 'Language';

  @override
  String get childprofile_physical => 'Physical';

  @override
  String get childprofile_calculation => 'Calculation';

  @override
  String get childprofile_unknownName => 'Unknown';

  @override
  String get childprofile_noHistory => 'No activity history';

  @override
  String get childprofile_startPlaying =>
      'Start playing activities to see stats here';

  @override
  String get childprofile_totalActivities => 'Total activities';

  @override
  String get childprofile_times => 'times';

  @override
  String get medalredemption_activity => 'Activity';

  @override
  String get medalredemption_done => 'DONE';

  @override
  String get medalredemption_points => 'points';

  @override
  String get playingresult_activity => 'Activity';

  @override
  String get playingresult_title => 'Playing result';

  @override
  String playingresult_session(int number) {
    return 'Session $number';
  }

  @override
  String get playingresult_scoreObtained => 'Score obtained';

  @override
  String get playingresult_diary => 'Diary';

  @override
  String get playingresult_noNotes => 'No notes';

  @override
  String get playingresult_image => 'Image';

  @override
  String get playingresult_video => 'Video';

  @override
  String get playingresult_videoAttached => 'Video attached';

  @override
  String get playingresult_timeSpent => 'Time spent';

  @override
  String get playingresult_noImage => 'No image';

  @override
  String get playingresult_sentencesSpoken => 'Sentences spoken';

  @override
  String playingresult_sentence(int number) {
    return 'Sentence $number';
  }

  @override
  String get playingresult_sentenceToSpeak => 'Sentence to speak:';

  @override
  String get playingresult_whatWasSpoken => 'What was spoken:';

  @override
  String get playingresult_noData => '(No data)';

  @override
  String get playingresult_noSpeechData => 'No speech data';

  @override
  String get playingresult_answerResults => 'Answer results';

  @override
  String playingresult_questionLabel(int number) {
    return 'Q.$number';
  }

  @override
  String playingresult_questionFallback(int number) {
    return 'Question $number';
  }

  @override
  String get summary_title => 'Review Your Recording';

  @override
  String get summary_completeActivity => 'Complete Activity';

  @override
  String summary_segmentLabel(int n) {
    return 'Segment $n';
  }

  @override
  String summary_pendingAnalysis(int n) {
    return '$n segment(s) still analyzing…';
  }

  @override
  String get summary_reRecord => 'Re-record';

  @override
  String get summary_notRecorded => 'Not recorded yet';

  @override
  String get summary_notRecordedShort => '—';

  @override
  String get summary_analyzing => 'Analyzing…';

  @override
  String get summary_analysisFailed =>
      'Analysis failed — tap Re-record to retry';

  @override
  String get summary_youSaid => 'You said';

  @override
  String get summary_error => 'Error';

  @override
  String get summary_reviewShort => 'Review';

  @override
  String get summary_stopRecord => 'Stop';

  @override
  String get profile_gallery => 'Select an image from your gallery';

  @override
  String get profile_google => 'Use a Google profile picture';

  @override
  String get profile_facebook => 'Use a Facebook profile picture';

  @override
  String get math_simulation_scanBtn => 'Scan Answer Sheet';

  @override
  String get math_simulation_manualCheckBtn => 'Manual Grading (No Camera)';

  @override
  String get math_simulation_retakeBtn => 'Retake Answer Sheet Photo';

  @override
  String math_simulation_detectedHeader(int count) {
    return 'Detected all $count answers';
  }

  @override
  String get math_simulation_detectedHint =>
      'Tap pencil icon to edit if AI conversion is inaccurate';

  @override
  String get math_simulation_sectionTitle => 'DETECTED ANSWERS';

  @override
  String get math_simulation_ocrLabel => 'Scanned Answer: ';

  @override
  String get math_simulation_noData => 'No scan data (Manual grade)';

  @override
  String math_simulation_editTitle(int index) {
    return 'Edit Answer for Question $index';
  }

  @override
  String get math_simulation_editHint => 'Type correct mathematical answer...';

  @override
  String math_simulation_questionPrefix(String question) {
    return 'Question: $question';
  }

  @override
  String math_simulation_correctAnswerPrefix(String answer) {
    return 'Expected Answer: $answer';
  }

  @override
  String get math_simulation_prevBtn => 'PREVIOUS';

  @override
  String get math_simulation_nextBtn => 'NEXT';

  @override
  String get sing_languageBadge => 'Language';

  @override
  String get sing_heroTitle => 'Sing the song,\nwin the stars!';

  @override
  String get sing_selectOurSongs => 'Choose Our Songs';

  @override
  String get sing_readyToPlay => 'Ready to play';

  @override
  String get sing_createOwnSong => 'Create Your Own';

  @override
  String get sing_wordsOrSentences => 'Words / Sentences';

  @override
  String get sing_chooseSong => 'Choose Song';

  @override
  String sing_singingChildren(int count) {
    return 'Children singing together ($count)';
  }

  @override
  String get sing_tapAddChild => 'Tap here to add children';

  @override
  String sing_childrenAdded(int count) {
    return 'Added $count more child(ren)';
  }

  @override
  String get sing_startSinging => 'START SINGING';

  @override
  String get sing_noSongs => 'No songs are available right now';

  @override
  String get sing_familySongTitle => 'Create a Family Memory Song';

  @override
  String get sing_familySongSubtitle =>
      'Enter something your child should remember and turn it into a song';

  @override
  String get sing_trainingType => 'What would you like to practice?';

  @override
  String get sing_vocabulary => 'Vocabulary';

  @override
  String get sing_sentence => 'Sentence';

  @override
  String get sing_vocabularyPrompt => 'Words for your child to remember';

  @override
  String get sing_sentencePrompt => 'Sentences for your child to remember';

  @override
  String get sing_vocabularyHint => 'e.g. apple, banana, orange, happy';

  @override
  String get sing_sentenceHint => 'e.g. I brush my teeth every morning.';

  @override
  String get sing_musicStyle => 'Music Style';

  @override
  String get sing_styleKids => 'Fun Kids Song';

  @override
  String get sing_styleDance => 'Dance Pop';

  @override
  String get sing_styleWarm => 'Warm Slow Song';

  @override
  String get sing_styleHipHop => 'Kids Hip-Hop';

  @override
  String get sing_uiOnlyNotice =>
      'The interface is ready. Song generation will be connected in the next step.';

  @override
  String get sing_createSongButton => 'Create Song from This Content';

  @override
  String get sing_showChords => 'Show Parent Guitar Chords';

  @override
  String get sing_hideChords => 'Hide Guitar Chords';

  @override
  String get sing_chordsShown => 'Guitar chord mode is on';

  @override
  String get sing_chordsHidden => 'Guitar chords are hidden';

  @override
  String get sing_videoSyncHint => 'The dance video plays with the song';

  @override
  String get sing_evidenceAttached => 'Evidence attached';

  @override
  String get sing_captureEvidence => 'Take a photo or record evidence video';

  @override
  String get sing_attached => 'Attached';

  @override
  String get sing_recordVideo => 'Record Video';

  @override
  String get sing_takePhoto => 'Take Photo';

  @override
  String get sing_openVideo => 'Open Video';

  @override
  String get sing_songVocabulary => 'Song Vocabulary:';

  @override
  String sing_pronunciation(String value) {
    return 'Pronunciation: $value';
  }

  @override
  String sing_translation(String value) {
    return 'Meaning: $value';
  }

  @override
  String get sing_cameraPreparing => 'Preparing the camera...';

  @override
  String get sing_cameraRecording => 'Recording video with the song...';

  @override
  String get sing_hubSubtitle =>
      'Bilingual songs with a guitar chord mode for parents';

  @override
  String get sing_evaluationTitle => 'Evaluate Sing Together';

  @override
  String sing_selectMediaSource(String media) {
    return 'Select $media source';
  }

  @override
  String get sing_childFallback => 'Child';

  @override
  String sing_saveScoreError(String error) {
    return 'Could not save the score: $error';
  }

  @override
  String sing_scoreChild(String name) {
    return 'Score $name';
  }

  @override
  String get sing_scoreLabel => 'Score (0–100)';

  @override
  String sing_duration(int minutes, int seconds) {
    return 'Singing time: $minutes min $seconds sec';
  }

  @override
  String get sing_imageVideoEvidence => 'Photo / Video Evidence';

  @override
  String get sing_change => 'Change';

  @override
  String get sing_watchVideo => 'Watch Video 🎥';

  @override
  String sing_evaluateChildren(int count) {
    return 'Evaluate Children ($count)';
  }

  @override
  String get sing_notesTitle => 'Additional Comments';

  @override
  String get sing_notesHint =>
      'e.g. sang clearly and pronounced the vocabulary correctly...';

  @override
  String get sing_savingScore => 'Saving score...';

  @override
  String get sing_saveScore => 'Save Singing Score';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_pleaseWait => 'Please wait';

  @override
  String get common_add => 'Add';

  @override
  String common_attachmentError(String error) {
    return 'Could not attach media: $error';
  }

  @override
  String languageList_loadError(String error) {
    return 'Could not load activities: $error';
  }

  @override
  String get languageList_empty => 'No activities in this category yet';

  @override
  String get dynamic_listening => 'Listening...';

  @override
  String get dynamic_holdToSpeak => 'Hold to speak';

  @override
  String get dynamic_greatJob => 'Great job!';

  @override
  String get dynamic_niceTry => 'Nice try!';

  @override
  String get disclaimer_title => 'Software Terms of Use';

  @override
  String get disclaimer_acceptCheck =>
      'I have read, understood, and accepted these terms';

  @override
  String get disclaimer_acceptButton => 'Accept and Continue';

  @override
  String get disclaimer_intro =>
      'Skill Wallet Kizuna was developed for the 28th National Software Contest (NSC 2026) to support children\'s learning and skill development through family activities.';

  @override
  String get disclaimer_developers => 'Developers';

  @override
  String get disclaimer_advisor => 'Advisor';

  @override
  String get disclaimer_terms => 'Terms of Use';

  @override
  String get disclaimer_license =>
      'The intellectual property belongs to the developers. The developers permit NSTDA to distribute this software ‘as is’ for temporary, non-exclusive, educational or personal non-commercial use without charge.';

  @override
  String get disclaimer_liability =>
      'NSTDA and the developers are not liable for loss, damage, errors, software performance, or consequences related to its use. Users are responsible for operation and maintenance.';

  @override
  String get daily_singTogether => 'Sing Together';

  @override
  String get createActivity_physicalTitle => 'Create Physical Activity';

  @override
  String get createActivity_calculateTitle => 'Create Calculation Activity';

  @override
  String get createActivity_mathTitle => 'Create Math Problems Activity';

  @override
  String get createActivity_voiceTitle => 'Create Voice Quest';

  @override
  String get createActivity_spaceTitle => 'Create Space Adventure';

  @override
  String get createActivity_maxScoreRequired =>
      'Please enter the maximum score';

  @override
  String get createActivity_timeRequired => 'Please enter the time limit';

  @override
  String get createActivity_itemScoreRequired =>
      'Please enter the score per item';

  @override
  String get createActivity_wordCategory => 'Word Category';

  @override
  String get createActivity_timeLimit => 'Time Limit (Seconds)';

  @override
  String get createActivity_scorePerItem => 'Score Per Detected Item';

  @override
  String get wordCategory_animals => '🦁 Animals';

  @override
  String get wordCategory_food => '🍎 Food';

  @override
  String get wordCategory_vehicles => '🚀 Vehicles';

  @override
  String get wordCategory_nature => '🌈 Nature';

  @override
  String get wordCategory_bedroom => '🛏️ Bedroom';

  @override
  String get wordCategory_school => '🎒 School';

  @override
  String get disclaimer_developer1 => 'Mr. Kanok Klinsuwan';

  @override
  String get disclaimer_developer2 => 'Mr. Podjanan Osatanan';

  @override
  String get disclaimer_developer3 => 'Mr. Nawapon Kitinanprakorn';

  @override
  String get disclaimer_advisorName =>
      'Asst. Prof. Dr. Suwatchai Kamonsantiroj';

  @override
  String math_scanCorrect(int index, String text) {
    return 'Question $index: detected “$text” (correct ✓)';
  }

  @override
  String math_scanIncorrect(int index, String text) {
    return 'Question $index: detected “$text” (does not match)';
  }

  @override
  String get math_noRecognition => 'No result was detected from the image';

  @override
  String math_scanQuestionError(int index, String error) {
    return 'Could not scan question $index: $error';
  }

  @override
  String get math_noAnswerFound => 'No answer found';

  @override
  String get math_invalidServerResponse =>
      'The server returned an invalid response';

  @override
  String math_scanError(String error) {
    return 'Scan failed: $error';
  }

  @override
  String math_submitError(String error) {
    return 'Submission failed: $error';
  }

  @override
  String get math_scanResultTitle => 'Answer Scan Results';

  @override
  String get math_activityTitle => 'Math Scenario Activity';

  @override
  String get math_exitTvMode => 'Exit Smart TV Mode';

  @override
  String math_questionImage(int index) {
    return 'Question $index image';
  }

  @override
  String get math_swipeNextImage => 'Swipe to view the next image';

  @override
  String get math_end => 'End';

  @override
  String get math_noImage => 'No image is available for this question';

  @override
  String get math_activityDetails => 'Activity Details';

  @override
  String get math_defaultDescription =>
      'Practice analytical thinking and solve math problems from real-world images. Write each answer on paper before scanning.';

  @override
  String get math_paperInstruction =>
      'Prepare paper and a pencil. Write each number clearly so the camera can scan it.';

  @override
  String math_questionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get math_proposition => 'PROBLEM SCENARIO';

  @override
  String get math_reviewAll => 'Review All Results';

  @override
  String math_cameraCheck(int index) {
    return 'Check with Camera (Question $index)';
  }

  @override
  String get math_readingHandwriting => 'Reading handwriting from the photo...';

  @override
  String math_readCorrect(String text) {
    return 'Detected “$text” (correct ✓)';
  }

  @override
  String math_readIncorrect(String text) {
    return 'Detected “$text” (does not match)';
  }

  @override
  String get math_takePhotoHint =>
      'Photograph the handwritten answer for this question';

  @override
  String get math_thisQuestionImage => 'This Question\'s Image';

  @override
  String get math_readingAi => 'AI is reading the handwriting...';

  @override
  String get math_retakeQuestion => 'Retake This Question';

  @override
  String get math_scanQuestion => 'Take Photo / Scan This Question';

  @override
  String get math_editNumber => 'Edit Number';

  @override
  String get math_readingAll => 'Reading Answers from the Image';

  @override
  String get math_waitFindingNumbers =>
      'Please wait while the system finds all numbers';

  @override
  String get math_checkAll => 'Check All Answers';

  @override
  String get math_reviewBeforeFinish =>
      'Review and edit the results before finishing';

  @override
  String get math_answerList => 'Answer List';

  @override
  String math_solutionValue(String value) {
    return 'Solution: $value';
  }

  @override
  String get math_noAnswerDetected => 'No answer detected';

  @override
  String get math_rescan => 'Scan Again';

  @override
  String get math_wellDone => 'Well Done!';

  @override
  String get math_rewardSaved => 'Your score and reward points have been saved';

  @override
  String history_redeemed(String name) {
    return 'Redeemed $name';
  }

  @override
  String get history_rewardFallback => 'Reward';

  @override
  String spaceScan_pickerError(String error) {
    return 'Unable to open image picker: $error';
  }

  @override
  String get spaceScan_failed => 'Scan failed.';

  @override
  String spaceScan_reason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get spaceScan_selectSource => 'Select image source';

  @override
  String get spaceScan_scanFirst =>
      'Please scan your room to find adventure objects first!';

  @override
  String get spaceScan_deleteItem => 'Delete Item?';

  @override
  String spaceScan_deleteConfirm(String item) {
    return 'Are you sure you want to remove “$item” from this quest?';
  }

  @override
  String get spaceScan_delete => 'Delete';

  @override
  String get spaceScan_noTargets =>
      'This area does not have any target items yet.';

  @override
  String get spaceScan_choosePreset => 'Choose preset area';

  @override
  String get spaceScan_presetDescription =>
      'Use target items managed in Space Adventure CMS.';

  @override
  String get spaceScan_noPresets =>
      'No preset areas are available yet.\nPlease add one in Space Adventure CMS.';

  @override
  String get spaceScan_phase => 'Phase 1: Room scan';

  @override
  String get spaceScan_intro =>
      'Take a photo of your room to find quest items.';

  @override
  String get spaceScan_usePreset => 'Use preset';

  @override
  String get spaceScan_cmsItems => 'CMS item list';

  @override
  String get spaceScan_scanRoom => 'Scan room';

  @override
  String get spaceScan_findItems => 'Find items in photo';

  @override
  String get spaceScan_tapPhoto => 'Tap below to take a photo';

  @override
  String get spaceScan_scanning => 'Scanning for items...';

  @override
  String get spaceScan_itemsDetected => 'Items detected:';

  @override
  String get spaceScan_startQuest => 'Start quest';

  @override
  String get spaceScan_rescan => 'Re-scan';

  @override
  String get dynamic_languageTitle => 'Language';

  @override
  String get dynamic_tagline => 'Say the word,\nwin the stars!';

  @override
  String get dynamic_chooseCategory => 'Choose Category';

  @override
  String get dynamic_todayGoal => 'TODAY\'S GOAL';

  @override
  String get dynamic_startQuest => 'Start Quest';

  @override
  String get dynamic_exitTvMode => 'Exit TV Mode';

  @override
  String get dynamic_tvMode => 'TV Mode';

  @override
  String get dynamic_listen => 'Listen';

  @override
  String dynamic_progress(int current, int total) {
    return 'Word $current of $total';
  }

  @override
  String get dynamic_sayWord => 'Say the word:';

  @override
  String dynamic_meaning(String meaning) {
    return 'Meaning: $meaning';
  }

  @override
  String dynamic_listenWord(String word) {
    return 'Listen: $word';
  }

  @override
  String get dynamic_evaluating => 'Evaluating your voice...';

  @override
  String get dynamic_speakInstruction =>
      'Press and hold while speaking. Release when done.';

  @override
  String get dynamic_youSaid => 'YOU SAID:';

  @override
  String dynamic_targetWord(String word) {
    return 'Target word: $word';
  }

  @override
  String get dynamic_listenVoice => 'Listen to your voice';

  @override
  String get dynamic_speakAgain => 'Speak Again';

  @override
  String get dynamic_questComplete => 'Quest Complete!';

  @override
  String get dynamic_totalScore => 'Total Score';

  @override
  String get dynamic_playRecordingError => 'Cannot play this recording.';

  @override
  String get dynamic_micPermission =>
      'Microphone permission denied. Please allow mic access!';

  @override
  String get dynamic_noSpeech =>
      'No speech heard. Hold the mic and speak clearly!';

  @override
  String get spaceQuest_timeout => 'Space time warp! Time ran out!';

  @override
  String get spaceQuest_verifyError => 'Verification error, please try again!';

  @override
  String get spaceQuest_objectHunter => 'Object Hunter';

  @override
  String spaceQuest_score(int score) {
    return 'Score: $score';
  }

  @override
  String spaceQuest_mission(int current, int total) {
    return 'SPACE MISSION QUEST $current/$total';
  }

  @override
  String get spaceQuest_capture => 'Capture the item';

  @override
  String get spaceQuest_findTake => 'Find and take a photo of the item';

  @override
  String get spaceQuest_verify => 'Verify match';

  @override
  String get spaceQuest_selectChild =>
      'Please select a child profile before saving the score.';

  @override
  String get spaceQuest_shareWeb =>
      'Sharing is supported on mobile devices. Right-click the image to save on Web!';

  @override
  String get spaceQuest_sharePhoto => 'Share photo';

  @override
  String get spaceQuest_recapture => 'Recapture';

  @override
  String get spaceQuest_complete => 'Quest Complete!';

  @override
  String get spaceQuest_totalScore => 'Total Score';

  @override
  String get addChild_title => 'Add Your Little Adventurer!';

  @override
  String get addChild_subtitle =>
      'Add your child and start building healthy habits together.';

  @override
  String get addChild_name => 'Your Child Name';

  @override
  String get addChild_nameHint => 'e.g. Pokpong';

  @override
  String get addChild_birthDate => 'Date of Birth';

  @override
  String get addChild_relationship => 'Relationship';

  @override
  String get addChild_mother => 'Mother';

  @override
  String get addChild_button => 'Add Child';

  @override
  String get home_welcomeBack => 'Welcome back';

  @override
  String get home_whosHere => 'Who\'s here?';

  @override
  String get home_add => 'Add';

  @override
  String get home_rewardPoints => 'Reward points';

  @override
  String get home_redeem => 'Redeem';

  @override
  String get home_activities => 'Activities';

  @override
  String get home_newBadge => 'NEW';

  @override
  String get home_spaceDescription => 'Scan your room and find hidden items!';

  @override
  String get common_continueGoogle => 'Continue with Google';

  @override
  String get common_continueFacebook => 'Continue with Facebook';

  @override
  String get common_home => 'Home';

  @override
  String get common_disclaimer => 'Disclaimer';

  @override
  String get common_login => 'Log In';

  @override
  String get common_copiedShareText => 'Copied share text';

  @override
  String get common_copyShareText => 'Copy share text';

  @override
  String get createActivity_choosePrompt =>
      'Choose the activity you want to create';

  @override
  String get sing_difficultyEasy => 'EASY';

  @override
  String get sing_highScore => 'High: 100';

  @override
  String get sing_durationMinutes => '10 Min';

  @override
  String get dynamic_todayCategory => 'TODAY\'S CATEGORY';

  @override
  String get dynamic_speaking => 'Speaking';

  @override
  String get dynamic_silence => '(Silence)';

  @override
  String dynamic_scoreEarned(int score) {
    return '+$score Score';
  }

  @override
  String get dynamic_perfect => 'Perfect! 🏆';

  @override
  String dynamic_voiceMatch(int percent) {
    return '$percent% Voice Match 🎙';
  }

  @override
  String get dynamic_nextWord => 'Next word';

  @override
  String spaceQuest_findItem(String item) {
    return 'FIND ITEM: $item';
  }

  @override
  String get spaceQuest_timeoutReason => 'Time ran out before verification!';

  @override
  String get spaceQuest_scanResults => 'Scan results';

  @override
  String get spaceQuest_correctMatch => 'CORRECT MATCH';

  @override
  String get spaceQuest_mismatch => 'MISMATCH DETECTED';

  @override
  String spaceQuest_verifiedTarget(String item) {
    return 'Vision AI verified your target: $item';
  }

  @override
  String spaceQuest_notMatched(String item) {
    return 'This photo does not match $item yet. Please try again.';
  }

  @override
  String spaceQuest_scored(int points, int total) {
    return 'Scored +$points points! Current total: $total';
  }

  @override
  String spaceQuest_currentTotal(int total) {
    return 'Current total: $total points';
  }

  @override
  String get spaceQuest_saving => 'Saving score...';

  @override
  String get spaceQuest_next => 'Next quest';

  @override
  String get home_parentFallback => 'Parent';

  @override
  String get welcome_intro =>
      'Let\'s get started!\nAlready part of our community? Welcome back.\nNew here? Join us to learn and grow together.';

  @override
  String get common_shareDownloadImage => 'Share / Download image';

  @override
  String itemintro_noSegments(String name) {
    return 'Error: No segments found for $name.';
  }

  @override
  String get record_streamUnsupported =>
      'Recording stream is not supported in this browser.';
}
