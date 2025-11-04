import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'App Nutrition'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginWithGoogle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountRegister;

  /// No description provided for @notVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account not verified'**
  String get notVerifiedTitle;

  /// No description provided for @notVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t verified yet. Do you want to resend the code or enter an existing one?'**
  String get notVerifiedBody;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'Code resent (check console or your email)'**
  String get codeResent;

  /// No description provided for @badCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get badCredentials;

  /// No description provided for @googleCancelledOrFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in cancelled or failed'**
  String get googleCancelledOrFailed;

  /// No description provided for @googleEmailMissing.
  ///
  /// In en, this message translates to:
  /// **'Unable to retrieve Google email.'**
  String get googleEmailMissing;

  /// No description provided for @noLocalAccountForGoogle.
  ///
  /// In en, this message translates to:
  /// **'No local account linked to this Google email. Please register.'**
  String get noLocalAccountForGoogle;

  /// No description provided for @appBarLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get appBarLogin;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your nutrition goals\nand track your progress'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Start your journey\ntowards better nutrition'**
  String get welcomeTagline;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccountLogin;

  /// No description provided for @appBarRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get appBarRegister;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get registerTitle;

  /// No description provided for @greetingUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}! 👋'**
  String greetingUser(Object name);

  /// No description provided for @dashboardTagline.
  ///
  /// In en, this message translates to:
  /// **'Track your goals daily'**
  String get dashboardTagline;

  /// No description provided for @dailyNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Nutrition'**
  String get dailyNutritionTitle;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesLabel;

  /// No description provided for @proteinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Proteins'**
  String get proteinsLabel;

  /// No description provided for @waterLabel.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterLabel;

  /// No description provided for @myObjectivesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Goals'**
  String get myObjectivesTitle;

  /// No description provided for @noObjectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals'**
  String get noObjectiveTitle;

  /// No description provided for @noObjectiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first goal to get started'**
  String get noObjectiveSubtitle;

  /// No description provided for @newObjectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get newObjectiveTitle;

  /// No description provided for @createObjectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a goal'**
  String get createObjectiveTitle;

  /// No description provided for @createObjectiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Define your personalized goals'**
  String get createObjectiveSubtitle;

  /// No description provided for @progression.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progression;

  /// No description provided for @daysRemainingSuffix.
  ///
  /// In en, this message translates to:
  /// **'days remaining'**
  String get daysRemainingSuffix;

  /// No description provided for @themeLightTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch to light theme'**
  String get themeLightTooltip;

  /// No description provided for @themeDarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get themeDarkTooltip;

  /// No description provided for @editObjectiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Goal updated successfully'**
  String get editObjectiveSuccess;

  /// No description provided for @deleteObjectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get deleteObjectiveTitle;

  /// No description provided for @deleteObjectiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the goal \"{name}\"?\n\nThis action is irreversible.'**
  String deleteObjectiveConfirm(Object name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteObjectiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted successfully'**
  String get deleteObjectiveSuccess;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error while loading'**
  String get errorLoading;

  /// No description provided for @errorDeleting.
  ///
  /// In en, this message translates to:
  /// **'Error while deleting'**
  String get errorDeleting;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get navRewards;

  /// No description provided for @navNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationTitle;

  /// No description provided for @verificationSentTo.
  ///
  /// In en, this message translates to:
  /// **'A verification code was sent to {email}. Enter it below.'**
  String verificationSentTo(Object email);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Account verified.'**
  String get accountVerified;

  /// No description provided for @invalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code.'**
  String get invalidOrExpiredCode;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotIntroEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset code'**
  String get forgotIntroEmail;

  /// No description provided for @forgotIntroCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code you received and your new password'**
  String get forgotIntroCode;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @resetCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get resetCodeLabel;

  /// No description provided for @enterCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code'**
  String get enterCodePrompt;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @passwordRules.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, one uppercase, one lowercase and a number'**
  String get passwordRules;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password too weak'**
  String get weakPassword;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordButton;

  /// No description provided for @codeSentCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Code sent. Check your email (or console in dev).'**
  String get codeSentCheckEmail;

  /// No description provided for @noAccountForEmail.
  ///
  /// In en, this message translates to:
  /// **'No account is associated with this email.'**
  String get noAccountForEmail;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorGeneric;

  /// No description provided for @logoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTooltip;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileTitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete your account? This action is irreversible.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get updateSuccess;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset. You can now sign in.'**
  String get passwordResetSuccess;

  /// No description provided for @nutritionTagline.
  ///
  /// In en, this message translates to:
  /// **'Track your daily nutrition'**
  String get nutritionTagline;

  /// No description provided for @outOfValue.
  ///
  /// In en, this message translates to:
  /// **'of {value}'**
  String outOfValue(Object value);

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get tabMacros;

  /// No description provided for @tabTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tabTips;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @snack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get snack;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @addMeal.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get addMeal;

  /// No description provided for @dailyTotal.
  ///
  /// In en, this message translates to:
  /// **'Daily total'**
  String get dailyTotal;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! 🎉'**
  String get goalReached;

  /// No description provided for @calorieDistribution.
  ///
  /// In en, this message translates to:
  /// **'Calorie distribution'**
  String get calorieDistribution;

  /// No description provided for @carbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbsLabel;

  /// No description provided for @fatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get fatsLabel;

  /// No description provided for @fiberLabel.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get fiberLabel;

  /// No description provided for @macronutrients.
  ///
  /// In en, this message translates to:
  /// **'Macronutrients'**
  String get macronutrients;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @addFoodToMeal.
  ///
  /// In en, this message translates to:
  /// **'Add a food to {meal}'**
  String addFoodToMeal(Object meal);

  /// No description provided for @myRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'My rewards'**
  String get myRewardsTitle;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsLabel;

  /// No description provided for @achievementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsLabel;

  /// No description provided for @objectivesLabel.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get objectivesLabel;

  /// No description provided for @achievementUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked!'**
  String get achievementUnlockedTitle;

  /// No description provided for @awesomeButton.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesomeButton;

  /// No description provided for @objectiveTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal type'**
  String get objectiveTypeLabel;

  /// No description provided for @targetValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Target value ({unit})'**
  String targetValueLabel(Object unit);

  /// No description provided for @enterTargetValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a target value'**
  String get enterTargetValue;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @valueMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'The value must be positive'**
  String get valueMustBePositive;

  /// No description provided for @deadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineLabel;

  /// No description provided for @timeRemainingDays.
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {days} days'**
  String timeRemainingDays(Object days);

  /// No description provided for @createGoalButton.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get createGoalButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @tapPlusToCreate.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create one.'**
  String get tapPlusToCreate;

  /// No description provided for @targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get targetLabel;

  /// No description provided for @deadlineColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineColonLabel;

  /// No description provided for @tipsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition tips'**
  String get tipsSectionTitle;

  /// No description provided for @tipHydrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Optimal Hydration'**
  String get tipHydrationTitle;

  /// No description provided for @tipHydrationBody.
  ///
  /// In en, this message translates to:
  /// **'Aim for 6–8 glasses of water per day; adjust with activity and climate.'**
  String get tipHydrationBody;

  /// No description provided for @tipBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Balanced Plate'**
  String get tipBalanceTitle;

  /// No description provided for @tipBalanceBody.
  ///
  /// In en, this message translates to:
  /// **'Fill half your plate with veggies, a quarter protein, a quarter smart carbs.'**
  String get tipBalanceBody;

  /// No description provided for @tipProteinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Essential Proteins'**
  String get tipProteinsTitle;

  /// No description provided for @tipProteinsBody.
  ///
  /// In en, this message translates to:
  /// **'Include lean proteins in each meal to support satiety and recovery.'**
  String get tipProteinsBody;

  /// No description provided for @tipMealTimingTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Timing'**
  String get tipMealTimingTitle;

  /// No description provided for @tipMealTimingBody.
  ///
  /// In en, this message translates to:
  /// **'Eat regularly and avoid long gaps to stabilize energy and appetite.'**
  String get tipMealTimingBody;

  /// No description provided for @tipSmartCarbsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Carbs'**
  String get tipSmartCarbsTitle;

  /// No description provided for @tipSmartCarbsBody.
  ///
  /// In en, this message translates to:
  /// **'Prefer whole grains, legumes, and fruits over refined sugars.'**
  String get tipSmartCarbsBody;

  /// No description provided for @tipHealthyFatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Healthy Fats'**
  String get tipHealthyFatsTitle;

  /// No description provided for @tipHealthyFatsBody.
  ///
  /// In en, this message translates to:
  /// **'Use olive oil, nuts, and fatty fish to support heart and brain health.'**
  String get tipHealthyFatsBody;

  /// No description provided for @achFirstGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'First Goal'**
  String get achFirstGoalTitle;

  /// No description provided for @achFirstGoalDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your very first goal.'**
  String get achFirstGoalDesc;

  /// No description provided for @achGoalReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Reached'**
  String get achGoalReachedTitle;

  /// No description provided for @achGoalReachedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach one of your goals.'**
  String get achGoalReachedDesc;

  /// No description provided for @achDeterminationTitle.
  ///
  /// In en, this message translates to:
  /// **'Determination'**
  String get achDeterminationTitle;

  /// No description provided for @achDeterminationDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your progress consistently for a week.'**
  String get achDeterminationDesc;

  /// No description provided for @achChampionTitle.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get achChampionTitle;

  /// No description provided for @achChampionDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach multiple goals—keep going!'**
  String get achChampionDesc;

  /// No description provided for @achConsistencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get achConsistencyTitle;

  /// No description provided for @achConsistencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Log your actions 7 days in a row.'**
  String get achConsistencyDesc;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
