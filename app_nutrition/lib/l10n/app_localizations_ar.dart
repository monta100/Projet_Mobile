// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تغذية التطبيق';

  @override
  String get welcome => 'مرحباً';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginWithGoogle => 'تسجيل الدخول عبر جوجل';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get noAccountRegister => 'ليس لديك حساب؟ سجّل الآن';

  @override
  String get notVerifiedTitle => 'الحساب غير مُفعّل';

  @override
  String get notVerifiedBody =>
      'حسابك غير مُفعّل بعد. هل تريد إعادة إرسال الرمز أم إدخال رمز موجود؟';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get enterCode => 'إدخال الرمز';

  @override
  String get cancel => 'إلغاء';

  @override
  String get userNotFound => 'المستخدم غير موجود';

  @override
  String get codeResent => 'تم إرسال الرمز (تحقق من البريد أو وحدة التحكم)';

  @override
  String get badCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get googleCancelledOrFailed => 'تم إلغاء تسجيل الدخول عبر جوجل أو فشل';

  @override
  String get googleEmailMissing => 'تعذر الحصول على البريد الإلكتروني من جوجل.';

  @override
  String get noLocalAccountForGoogle =>
      'لا يوجد حساب محلي مرتبط بهذا البريد في جوجل. الرجاء التسجيل.';

  @override
  String get appBarLogin => 'تسجيل الدخول';

  @override
  String get enterEmail => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get invalidEmail => 'صيغة البريد الإلكتروني غير صحيحة';

  @override
  String get enterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get welcomeSubtitle => 'أدِر أهدافك الغذائية\nوتابع تقدمك';

  @override
  String get welcomeTagline => 'ابدأ رحلتك\nنحو تغذية أفضل';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get alreadyHaveAccountLogin => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get appBarRegister => 'التسجيل';

  @override
  String get registerTitle => 'أنشئ حسابًا';

  @override
  String greetingUser(Object name) {
    return 'مرحباً، $name! 👋';
  }

  @override
  String get dashboardTagline => 'تابع أهدافك يوميًا';

  @override
  String get dailyNutritionTitle => 'التغذية اليوم';

  @override
  String get caloriesLabel => 'السعرات الحرارية';

  @override
  String get proteinsLabel => 'البروتينات';

  @override
  String get waterLabel => 'الماء';

  @override
  String get myObjectivesTitle => 'أهدافي';

  @override
  String get noObjectiveTitle => 'لا توجد أهداف';

  @override
  String get noObjectiveSubtitle => 'أنشئ هدفك الأول للبدء';

  @override
  String get newObjectiveTitle => 'هدف جديد';

  @override
  String get createObjectiveTitle => 'إنشاء هدف';

  @override
  String get createObjectiveSubtitle => 'حدّد أهدافك المخصّصة';

  @override
  String get progression => 'التقدم';

  @override
  String get daysRemainingSuffix => 'أيام متبقية';

  @override
  String get themeLightTooltip => 'تفعيل النمط الفاتح';

  @override
  String get themeDarkTooltip => 'تفعيل النمط الداكن';

  @override
  String get editObjectiveSuccess => 'تم تعديل الهدف بنجاح';

  @override
  String get deleteObjectiveTitle => 'حذف الهدف';

  @override
  String deleteObjectiveConfirm(Object name) {
    return 'هل أنت متأكد من حذف الهدف \"$name\"؟\n\nهذا الإجراء لا يمكن التراجع عنه.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get deleteObjectiveSuccess => 'تم حذف الهدف بنجاح';

  @override
  String get errorLoading => 'حدث خطأ أثناء التحميل';

  @override
  String get errorDeleting => 'حدث خطأ أثناء الحذف';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navRewards => 'الإنجازات';

  @override
  String get navNutrition => 'التغذية';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get verificationTitle => 'التحقق';

  @override
  String verificationSentTo(Object email) {
    return 'تم إرسال رمز تحقق إلى $email. أدخله أدناه.';
  }

  @override
  String get codeLabel => 'الرمز';

  @override
  String get verifyButton => 'تحقق';

  @override
  String get accountVerified => 'تم تفعيل الحساب.';

  @override
  String get invalidOrExpiredCode => 'رمز غير صالح أو منتهي الصلاحية.';

  @override
  String get forgotPasswordTitle => 'نسيت كلمة المرور';

  @override
  String get forgotIntroEmail =>
      'أدخل بريدك الإلكتروني لاستلام رمز إعادة التعيين';

  @override
  String get forgotIntroCode => 'أدخل الرمز المستلم وكلمة المرور الجديدة';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get resetCodeLabel => 'رمز إعادة التعيين';

  @override
  String get enterCodePrompt => 'يرجى إدخال الرمز';

  @override
  String get invalidCode => 'رمز غير صالح';

  @override
  String get newPasswordLabel => 'كلمة مرور جديدة';

  @override
  String get passwordRules => 'على الأقل 8 أحرف، حرف كبير، حرف صغير ورقم';

  @override
  String get weakPassword => 'كلمة المرور ضعيفة';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get pleaseConfirmPassword => 'يرجى تأكيد كلمة المرور';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get resetPasswordButton => 'إعادة تعيين كلمة المرور';

  @override
  String get codeSentCheckEmail =>
      'تم إرسال الرمز. تحقق من بريدك (أو وحدة التحكم في التطوير).';

  @override
  String get noAccountForEmail => 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';

  @override
  String get errorGeneric => 'خطأ';

  @override
  String get logoutTooltip => 'تسجيل الخروج';

  @override
  String get profileTitle => 'ملفي الشخصي';

  @override
  String get deleteAccountConfirm =>
      'هل تريد حقًا حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.';

  @override
  String get deleteAccountTitle => 'حذف الحساب';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get deleteMyAccount => 'حذف حسابي';

  @override
  String get updateSuccess => 'تم تحديث الملف الشخصي';

  @override
  String get updateFailed => 'فشل التحديث';

  @override
  String get passwordResetSuccess =>
      'تمت إعادة تعيين كلمة المرور. يمكنك تسجيل الدخول الآن.';

  @override
  String get nutritionTagline => 'تابع تغذيتك اليومية';

  @override
  String outOfValue(Object value) {
    return 'من $value';
  }

  @override
  String get tabToday => 'اليوم';

  @override
  String get tabMacros => 'المغذيات الكلية';

  @override
  String get tabTips => 'نصائح';

  @override
  String get breakfast => 'فطور';

  @override
  String get lunch => 'غداء';

  @override
  String get snack => 'وجبة خفيفة';

  @override
  String get dinner => 'عشاء';

  @override
  String get addMeal => 'أضف وجبة';

  @override
  String get dailyTotal => 'إجمالي اليوم';

  @override
  String get remaining => 'متبقية';

  @override
  String get goalReached => 'تم تحقيق الهدف! 🎉';

  @override
  String get calorieDistribution => 'توزيع السعرات';

  @override
  String get carbsLabel => 'الكربوهيدرات';

  @override
  String get fatsLabel => 'الدهون';

  @override
  String get fiberLabel => 'الألياف';

  @override
  String get macronutrients => 'المغذيات الكلية';

  @override
  String get edit => 'تعديل';

  @override
  String get learnMore => 'اعرف المزيد';

  @override
  String get gotIt => 'فهمت';

  @override
  String addFoodToMeal(Object meal) {
    return 'أضف طعامًا إلى $meal';
  }

  @override
  String get myRewardsTitle => 'مكافآتي';

  @override
  String get pointsLabel => 'النقاط';

  @override
  String get achievementsLabel => 'الإنجازات';

  @override
  String get objectivesLabel => 'الأهداف';

  @override
  String get achievementUnlockedTitle => 'تم فتح إنجاز!';

  @override
  String get awesomeButton => 'رائع!';

  @override
  String get objectiveTypeLabel => 'نوع الهدف';

  @override
  String targetValueLabel(Object unit) {
    return 'القيمة المستهدفة ($unit)';
  }

  @override
  String get enterTargetValue => 'يرجى إدخال قيمة مستهدفة';

  @override
  String get enterValidNumber => 'يرجى إدخال رقم صالح';

  @override
  String get valueMustBePositive => 'يجب أن تكون القيمة موجبة';

  @override
  String get deadlineLabel => 'الموعد النهائي';

  @override
  String timeRemainingDays(Object days) {
    return 'الوقت المتبقي: $days يومًا';
  }

  @override
  String get createGoalButton => 'إنشاء الهدف';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get tapPlusToCreate => 'انقر + لإنشاء هدف.';

  @override
  String get targetLabel => 'الهدف';

  @override
  String get deadlineColonLabel => 'الموعد النهائي';

  @override
  String get tipsSectionTitle => 'نصائح التغذية';

  @override
  String get tipHydrationTitle => 'ترطيب مثالي';

  @override
  String get tipHydrationBody =>
      'استهدف 6–8 أكواب ماء يوميًا؛ وعدّل حسب النشاط والمناخ.';

  @override
  String get tipBalanceTitle => 'طبق متوازن';

  @override
  String get tipBalanceBody =>
      'نصف الطبق خضار، ربع بروتين، ربع كربوهيدرات ذكية.';

  @override
  String get tipProteinsTitle => 'بروتينات أساسية';

  @override
  String get tipProteinsBody =>
      'أضف بروتينات خفيفة لكل وجبة لدعم الشبع والتعافي.';

  @override
  String get tipMealTimingTitle => 'توقيت الوجبات';

  @override
  String get tipMealTimingBody =>
      'تناول الوجبات بانتظام وتجنّب الفترات الطويلة دون طعام.';

  @override
  String get tipSmartCarbsTitle => 'كربوهيدرات ذكية';

  @override
  String get tipSmartCarbsBody =>
      'فضّل الحبوب الكاملة والبقوليات والفواكه على السكريات المكررة.';

  @override
  String get tipHealthyFatsTitle => 'دهون صحية';

  @override
  String get tipHealthyFatsBody =>
      'استخدم زيت الزيتون والمكسرات والأسماك الدهنية لصحة القلب والدماغ.';

  @override
  String get achFirstGoalTitle => 'أول هدف';

  @override
  String get achFirstGoalDesc => 'أنشئ هدفك الأول.';

  @override
  String get achGoalReachedTitle => 'تم تحقيق الهدف';

  @override
  String get achGoalReachedDesc => 'حقق أحد أهدافك.';

  @override
  String get achDeterminationTitle => 'عزيمة';

  @override
  String get achDeterminationDesc => 'تابع تقدمك باستمرار لمدة أسبوع.';

  @override
  String get achChampionTitle => 'بطل';

  @override
  String get achChampionDesc => 'حقق عدة أهداف — استمر!';

  @override
  String get achConsistencyTitle => 'انتظام';

  @override
  String get achConsistencyDesc => 'سجّل نشاطك لمدة 7 أيام متتالية.';
}
