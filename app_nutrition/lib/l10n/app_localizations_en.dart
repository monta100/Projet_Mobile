// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'App Nutrition';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccountRegister => 'Don\'t have an account? Sign up';

  @override
  String get notVerifiedTitle => 'Account not verified';

  @override
  String get notVerifiedBody =>
      'Your account isn\'t verified yet. Do you want to resend the code or enter an existing one?';

  @override
  String get resendCode => 'Resend code';

  @override
  String get enterCode => 'Enter code';

  @override
  String get cancel => 'Cancel';

  @override
  String get userNotFound => 'User not found';

  @override
  String get codeResent => 'Code resent (check console or your email)';

  @override
  String get badCredentials => 'Incorrect email or password';

  @override
  String get googleCancelledOrFailed => 'Google sign-in cancelled or failed';

  @override
  String get googleEmailMissing => 'Unable to retrieve Google email.';

  @override
  String get noLocalAccountForGoogle =>
      'No local account linked to this Google email. Please register.';

  @override
  String get appBarLogin => 'Login';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get welcomeSubtitle =>
      'Manage your nutrition goals\nand track your progress';

  @override
  String get welcomeTagline => 'Start your journey\ntowards better nutrition';

  @override
  String get signUp => 'Sign up';

  @override
  String get alreadyHaveAccountLogin => 'Already have an account? Log in';

  @override
  String get appBarRegister => 'Register';

  @override
  String get registerTitle => 'Create an account';

  @override
  String greetingUser(Object name) {
    return 'Hello, $name! 👋';
  }

  @override
  String get dashboardTagline => 'Track your goals daily';

  @override
  String get dailyNutritionTitle => 'Today\'s Nutrition';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get proteinsLabel => 'Proteins';

  @override
  String get waterLabel => 'Water';

  @override
  String get myObjectivesTitle => 'My Goals';

  @override
  String get noObjectiveTitle => 'No goals';

  @override
  String get noObjectiveSubtitle => 'Create your first goal to get started';

  @override
  String get newObjectiveTitle => 'New goal';

  @override
  String get createObjectiveTitle => 'Create a goal';

  @override
  String get createObjectiveSubtitle => 'Define your personalized goals';

  @override
  String get progression => 'Progress';

  @override
  String get daysRemainingSuffix => 'days remaining';

  @override
  String get themeLightTooltip => 'Switch to light theme';

  @override
  String get themeDarkTooltip => 'Switch to dark theme';

  @override
  String get editObjectiveSuccess => 'Goal updated successfully';

  @override
  String get deleteObjectiveTitle => 'Delete goal';

  @override
  String deleteObjectiveConfirm(Object name) {
    return 'Are you sure you want to delete the goal \"$name\"?\n\nThis action is irreversible.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteObjectiveSuccess => 'Goal deleted successfully';

  @override
  String get errorLoading => 'Error while loading';

  @override
  String get errorDeleting => 'Error while deleting';

  @override
  String get navHome => 'Home';

  @override
  String get navRewards => 'Rewards';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navProfile => 'Profile';

  @override
  String get verificationTitle => 'Verification';

  @override
  String verificationSentTo(Object email) {
    return 'A verification code was sent to $email. Enter it below.';
  }

  @override
  String get codeLabel => 'Code';

  @override
  String get verifyButton => 'Verify';

  @override
  String get accountVerified => 'Account verified.';

  @override
  String get invalidOrExpiredCode => 'Invalid or expired code.';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotIntroEmail => 'Enter your email to receive a reset code';

  @override
  String get forgotIntroCode =>
      'Enter the code you received and your new password';

  @override
  String get sendCode => 'Send code';

  @override
  String get resetCodeLabel => 'Reset code';

  @override
  String get enterCodePrompt => 'Please enter the code';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get passwordRules =>
      'At least 8 characters, one uppercase, one lowercase and a number';

  @override
  String get weakPassword => 'Password too weak';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get resetPasswordButton => 'Reset password';

  @override
  String get codeSentCheckEmail =>
      'Code sent. Check your email (or console in dev).';

  @override
  String get noAccountForEmail => 'No account is associated with this email.';

  @override
  String get errorGeneric => 'Error';

  @override
  String get logoutTooltip => 'Logout';

  @override
  String get profileTitle => 'My profile';

  @override
  String get deleteAccountConfirm =>
      'Do you really want to delete your account? This action is irreversible.';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get updateSuccess => 'Profile updated';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get passwordResetSuccess => 'Password reset. You can now sign in.';

  @override
  String get nutritionTagline => 'Track your daily nutrition';

  @override
  String outOfValue(Object value) {
    return 'of $value';
  }

  @override
  String get tabToday => 'Today';

  @override
  String get tabMacros => 'Macros';

  @override
  String get tabTips => 'Tips';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get snack => 'Snack';

  @override
  String get dinner => 'Dinner';

  @override
  String get addMeal => 'Add meal';

  @override
  String get dailyTotal => 'Daily total';

  @override
  String get remaining => 'remaining';

  @override
  String get goalReached => 'Goal reached! 🎉';

  @override
  String get calorieDistribution => 'Calorie distribution';

  @override
  String get carbsLabel => 'Carbs';

  @override
  String get fatsLabel => 'Fats';

  @override
  String get fiberLabel => 'Fiber';

  @override
  String get macronutrients => 'Macronutrients';

  @override
  String get edit => 'Edit';

  @override
  String get learnMore => 'Learn more';

  @override
  String get gotIt => 'Got it';

  @override
  String addFoodToMeal(Object meal) {
    return 'Add a food to $meal';
  }

  @override
  String get myRewardsTitle => 'My rewards';

  @override
  String get pointsLabel => 'Points';

  @override
  String get achievementsLabel => 'Achievements';

  @override
  String get objectivesLabel => 'Goals';

  @override
  String get achievementUnlockedTitle => 'Achievement unlocked!';

  @override
  String get awesomeButton => 'Awesome!';

  @override
  String get objectiveTypeLabel => 'Goal type';

  @override
  String targetValueLabel(Object unit) {
    return 'Target value ($unit)';
  }

  @override
  String get enterTargetValue => 'Please enter a target value';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String get valueMustBePositive => 'The value must be positive';

  @override
  String get deadlineLabel => 'Deadline';

  @override
  String timeRemainingDays(Object days) {
    return 'Time remaining: $days days';
  }

  @override
  String get createGoalButton => 'Create goal';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get tapPlusToCreate => 'Tap + to create one.';

  @override
  String get targetLabel => 'Target';

  @override
  String get deadlineColonLabel => 'Deadline';

  @override
  String get tipsSectionTitle => 'Nutrition tips';

  @override
  String get tipHydrationTitle => 'Optimal Hydration';

  @override
  String get tipHydrationBody =>
      'Aim for 6–8 glasses of water per day; adjust with activity and climate.';

  @override
  String get tipBalanceTitle => 'Balanced Plate';

  @override
  String get tipBalanceBody =>
      'Fill half your plate with veggies, a quarter protein, a quarter smart carbs.';

  @override
  String get tipProteinsTitle => 'Essential Proteins';

  @override
  String get tipProteinsBody =>
      'Include lean proteins in each meal to support satiety and recovery.';

  @override
  String get tipMealTimingTitle => 'Meal Timing';

  @override
  String get tipMealTimingBody =>
      'Eat regularly and avoid long gaps to stabilize energy and appetite.';

  @override
  String get tipSmartCarbsTitle => 'Smart Carbs';

  @override
  String get tipSmartCarbsBody =>
      'Prefer whole grains, legumes, and fruits over refined sugars.';

  @override
  String get tipHealthyFatsTitle => 'Healthy Fats';

  @override
  String get tipHealthyFatsBody =>
      'Use olive oil, nuts, and fatty fish to support heart and brain health.';

  @override
  String get achFirstGoalTitle => 'First Goal';

  @override
  String get achFirstGoalDesc => 'Create your very first goal.';

  @override
  String get achGoalReachedTitle => 'Goal Reached';

  @override
  String get achGoalReachedDesc => 'Reach one of your goals.';

  @override
  String get achDeterminationTitle => 'Determination';

  @override
  String get achDeterminationDesc =>
      'Track your progress consistently for a week.';

  @override
  String get achChampionTitle => 'Champion';

  @override
  String get achChampionDesc => 'Reach multiple goals—keep going!';

  @override
  String get achConsistencyTitle => 'Consistency';

  @override
  String get achConsistencyDesc => 'Log your actions 7 days in a row.';
}
