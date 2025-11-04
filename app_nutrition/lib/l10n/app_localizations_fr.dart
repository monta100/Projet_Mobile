// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'App Nutrition';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Inscription';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get loginWithGoogle => 'Se connecter avec Google';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccountRegister => 'Pas encore de compte ? S\'inscrire';

  @override
  String get notVerifiedTitle => 'Compte non vérifié';

  @override
  String get notVerifiedBody =>
      'Votre compte n\'est pas encore vérifié. Voulez-vous renvoyer le code ou saisir un code existant ?';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get enterCode => 'Saisir le code';

  @override
  String get cancel => 'Annuler';

  @override
  String get userNotFound => 'Utilisateur introuvable';

  @override
  String get codeResent => 'Code renvoyé (vérifier la console ou votre mail)';

  @override
  String get badCredentials => 'Email ou mot de passe incorrect';

  @override
  String get googleCancelledOrFailed => 'Connexion Google annulée ou échouée';

  @override
  String get googleEmailMissing => 'Impossible de récupérer l\'email Google.';

  @override
  String get noLocalAccountForGoogle =>
      'Aucun compte local lié à cet email Google. Veuillez vous inscrire.';

  @override
  String get appBarLogin => 'Connexion';

  @override
  String get enterEmail => 'Veuillez saisir votre email';

  @override
  String get invalidEmail => 'Format d\'email invalide';

  @override
  String get enterPassword => 'Veuillez saisir votre mot de passe';

  @override
  String get welcomeSubtitle =>
      'Gérez vos objectifs nutritionnels\net suivez votre progression';

  @override
  String get welcomeTagline =>
      'Commencez votre parcours\nvers une meilleure nutrition';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get alreadyHaveAccountLogin => 'Déjà un compte ? Se connecter';

  @override
  String get appBarRegister => 'Inscription';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String greetingUser(Object name) {
    return 'Bonjour, $name ! 👋';
  }

  @override
  String get dashboardTagline => 'Suivez vos objectifs au quotidien';

  @override
  String get dailyNutritionTitle => 'Nutrition du jour';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get proteinsLabel => 'Protéines';

  @override
  String get waterLabel => 'Eau';

  @override
  String get myObjectivesTitle => 'Mes Objectifs';

  @override
  String get noObjectiveTitle => 'Aucun objectif';

  @override
  String get noObjectiveSubtitle =>
      'Créez votre premier objectif pour commencer';

  @override
  String get newObjectiveTitle => 'Nouvel objectif';

  @override
  String get createObjectiveTitle => 'Créer un objectif';

  @override
  String get createObjectiveSubtitle =>
      'Définissez vos objectifs personnalisés';

  @override
  String get progression => 'Progression';

  @override
  String get daysRemainingSuffix => 'jours restants';

  @override
  String get themeLightTooltip => 'Activer le thème clair';

  @override
  String get themeDarkTooltip => 'Activer le thème sombre';

  @override
  String get editObjectiveSuccess => 'Objectif modifié avec succès';

  @override
  String get deleteObjectiveTitle => 'Supprimer l\'objectif';

  @override
  String deleteObjectiveConfirm(Object name) {
    return 'Êtes-vous sûr de vouloir supprimer l\'objectif \"$name\" ?\n\nCette action est irréversible.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteObjectiveSuccess => 'Objectif supprimé avec succès';

  @override
  String get errorLoading => 'Erreur lors du chargement';

  @override
  String get errorDeleting => 'Erreur lors de la suppression';

  @override
  String get navHome => 'Accueil';

  @override
  String get navRewards => 'Récompenses';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navProfile => 'Profil';

  @override
  String get verificationTitle => 'Vérification';

  @override
  String verificationSentTo(Object email) {
    return 'Un code de vérification a été envoyé à $email. Saisissez-le ci-dessous.';
  }

  @override
  String get codeLabel => 'Code';

  @override
  String get verifyButton => 'Vérifier';

  @override
  String get accountVerified => 'Compte vérifié.';

  @override
  String get invalidOrExpiredCode => 'Code invalide ou expiré.';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotIntroEmail =>
      'Entrez votre email pour recevoir un code de réinitialisation';

  @override
  String get forgotIntroCode =>
      'Entrez le code reçu et votre nouveau mot de passe';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get resetCodeLabel => 'Code de réinitialisation';

  @override
  String get enterCodePrompt => 'Veuillez saisir le code';

  @override
  String get invalidCode => 'Code invalide';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get passwordRules =>
      'Au moins 8 caractères, une majuscule, une minuscule et un chiffre';

  @override
  String get weakPassword => 'Mot de passe trop faible';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordsDontMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get resetPasswordButton => 'Réinitialiser le mot de passe';

  @override
  String get codeSentCheckEmail =>
      'Code envoyé. Vérifiez votre email (ou la console en dev).';

  @override
  String get noAccountForEmail => 'Aucun compte n\'est associé à cet email.';

  @override
  String get errorGeneric => 'Erreur';

  @override
  String get logoutTooltip => 'Déconnexion';

  @override
  String get profileTitle => 'Mon profil';

  @override
  String get deleteAccountConfirm =>
      'Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.';

  @override
  String get deleteAccountTitle => 'Supprimer le compte';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get deleteMyAccount => 'Supprimer mon compte';

  @override
  String get updateSuccess => 'Profil mis à jour';

  @override
  String get updateFailed => 'Échec de la mise à jour';

  @override
  String get passwordResetSuccess =>
      'Mot de passe réinitialisé. Vous pouvez vous connecter.';

  @override
  String get nutritionTagline => 'Suivez votre nutrition quotidienne';

  @override
  String outOfValue(Object value) {
    return 'sur $value';
  }

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tabMacros => 'Macros';

  @override
  String get tabTips => 'Conseils';

  @override
  String get breakfast => 'Petit-déjeuner';

  @override
  String get lunch => 'Déjeuner';

  @override
  String get snack => 'Collation';

  @override
  String get dinner => 'Dîner';

  @override
  String get addMeal => 'Ajouter un repas';

  @override
  String get dailyTotal => 'Total du jour';

  @override
  String get remaining => 'restantes';

  @override
  String get goalReached => 'Objectif atteint ! 🎉';

  @override
  String get calorieDistribution => 'Répartition Calorique';

  @override
  String get carbsLabel => 'Glucides';

  @override
  String get fatsLabel => 'Lipides';

  @override
  String get fiberLabel => 'Fibres';

  @override
  String get macronutrients => 'Macronutriments';

  @override
  String get edit => 'Modifier';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get gotIt => 'J\'ai compris';

  @override
  String addFoodToMeal(Object meal) {
    return 'Ajouter un aliment à $meal';
  }

  @override
  String get myRewardsTitle => 'Mes Récompenses';

  @override
  String get pointsLabel => 'Points';

  @override
  String get achievementsLabel => 'Récompenses';

  @override
  String get objectivesLabel => 'Objectifs';

  @override
  String get achievementUnlockedTitle => 'Achievement Débloqué !';

  @override
  String get awesomeButton => 'Génial !';

  @override
  String get objectiveTypeLabel => 'Type d\'objectif';

  @override
  String targetValueLabel(Object unit) {
    return 'Valeur cible ($unit)';
  }

  @override
  String get enterTargetValue => 'Veuillez saisir une valeur cible';

  @override
  String get enterValidNumber => 'Veuillez saisir un nombre valide';

  @override
  String get valueMustBePositive => 'La valeur doit être positive';

  @override
  String get deadlineLabel => 'Date limite';

  @override
  String timeRemainingDays(Object days) {
    return 'Temps restant: $days jours';
  }

  @override
  String get createGoalButton => 'Créer l\'objectif';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get tapPlusToCreate => '+ pour en créer un.';

  @override
  String get targetLabel => 'Cible';

  @override
  String get deadlineColonLabel => 'Date limite';

  @override
  String get tipsSectionTitle => 'Conseils nutrition';

  @override
  String get tipHydrationTitle => 'Hydratation optimale';

  @override
  String get tipHydrationBody =>
      'Visez 6–8 verres d’eau par jour; ajustez selon l’activité et le climat.';

  @override
  String get tipBalanceTitle => 'Assiette équilibrée';

  @override
  String get tipBalanceBody =>
      'La moitié légumes, un quart protéines, un quart glucides de qualité.';

  @override
  String get tipProteinsTitle => 'Protéines essentielles';

  @override
  String get tipProteinsBody =>
      'Ajoutez des protéines maigres à chaque repas pour la satiété et la récupération.';

  @override
  String get tipMealTimingTitle => 'Rythme des repas';

  @override
  String get tipMealTimingBody =>
      'Mangez régulièrement et évitez de longues périodes à jeun.';

  @override
  String get tipSmartCarbsTitle => 'Glucides intelligents';

  @override
  String get tipSmartCarbsBody =>
      'Privilégiez céréales complètes, légumineuses et fruits aux sucres raffinés.';

  @override
  String get tipHealthyFatsTitle => 'Graisses saines';

  @override
  String get tipHealthyFatsBody =>
      'Huile d’olive, fruits à coque et poissons gras pour le cœur et le cerveau.';

  @override
  String get achFirstGoalTitle => 'Premier objectif';

  @override
  String get achFirstGoalDesc => 'Créez votre tout premier objectif.';

  @override
  String get achGoalReachedTitle => 'Objectif atteint';

  @override
  String get achGoalReachedDesc => 'Atteignez l’un de vos objectifs.';

  @override
  String get achDeterminationTitle => 'Détermination';

  @override
  String get achDeterminationDesc =>
      'Suivez vos progrès régulièrement pendant une semaine.';

  @override
  String get achChampionTitle => 'Champion';

  @override
  String get achChampionDesc => 'Atteignez plusieurs objectifs — continuez !';

  @override
  String get achConsistencyTitle => 'Régularité';

  @override
  String get achConsistencyDesc => 'Enregistrez vos actions 7 jours d’affilée.';
}
