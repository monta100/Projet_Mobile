import '../Entites/exercise.dart';
import '../Entites/exercise_plan.dart';
import '../Entites/exercise_session.dart';
import '../Entites/plan_exercise_assignment.dart';
import 'package:flutter/material.dart';
import '../Entites/user_plan_assignment.dart';
import '../Entites/utilisateur.dart';
import 'database_helper.dart';
import 'notification_service.dart';

class ExerciseService {
  final DatabaseHelper _db = DatabaseHelper();

  // --- Exercise Management ---

  /// Récupère tous les exercices actifs
  Future<List<Exercise>> getAllExercises() async {
    return await _db.getAllExercises();
  }

  /// Récupère un exercice par son ID
  Future<Exercise?> getExerciseById(int id) async {
    return await _db.getExerciseById(id);
  }

  /// Recherche des exercices par critères
  Future<List<Exercise>> searchExercises({
    String? query,
    String? type,
    String? niveau,
    String? objectif,
    String? partieCorps,
    String? materiel,
  }) async {
    List<Exercise> exercises = await _db.getAllExercises();
    
    // Filtrer par critères
    if (query != null && query.isNotEmpty) {
      exercises = exercises.where((e) => 
        e.nom.toLowerCase().contains(query.toLowerCase()) ||
        e.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    
    if (type != null && type.isNotEmpty) {
      exercises = exercises.where((e) => e.type.toLowerCase() == type.toLowerCase()).toList();
    }
    
    if (niveau != null && niveau.isNotEmpty) {
      exercises = exercises.where((e) => e.niveau.toLowerCase() == niveau.toLowerCase()).toList();
    }
    
    if (objectif != null && objectif.isNotEmpty) {
      exercises = exercises.where((e) => e.objectif.toLowerCase().contains(objectif.toLowerCase())).toList();
    }
    
    if (partieCorps != null && partieCorps.isNotEmpty) {
      exercises = exercises.where((e) => e.partieCorps.toLowerCase().contains(partieCorps.toLowerCase())).toList();
    }
    
    if (materiel != null && materiel.isNotEmpty) {
      exercises = exercises.where((e) => e.materiel.toLowerCase().contains(materiel.toLowerCase())).toList();
    }
    
    return exercises.where((e) => e.isActive).toList();
  }

  /// Récupère les exercices recommandés pour un utilisateur
  Future<List<Exercise>> getRecommendedExercises(Utilisateur user) async {
    // Logique de recommandation basée sur le profil utilisateur
    // Pour l'instant, retourne tous les exercices de niveau débutant
    return await _db.getExercisesByNiveau('débutant');
  }

  // --- Exercise Plan Management ---

  /// Crée un nouveau plan d'exercices
  Future<ExercisePlan> createExercisePlan({
    required int coachId,
    required String nom,
    required String description,
    String? notesCoach,
  }) async {
    final plan = ExercisePlan(
      coachId: coachId,
      nom: nom,
      description: description,
      dateCreation: DateTime.now(),
      notesCoach: notesCoach,
    );
    
    final planId = await _db.insertExercisePlan(plan);
    plan.id = planId;
    return plan;
  }

  /// Récupère les plans d'un coach
  Future<List<ExercisePlan>> getPlansByCoach(int coachId) async {
    return await _db.getExercisePlansByCoach(coachId);
  }

  /// Récupère un plan par son ID
  Future<ExercisePlan?> getPlanById(int id) async {
    return await _db.getExercisePlanById(id);
  }

  /// Ajoute un exercice à un plan
  Future<void> addExerciseToPlan({
    required int planId,
    required int exerciseId,
    required int ordre,
    required int nombreSeries,
    required int repetitionsParSerie,
    required int tempsRepos,
    String? notesPersonnalisees,
  }) async {
    final assignment = PlanExerciseAssignment(
      planId: planId,
      exerciseId: exerciseId,
      ordre: ordre,
      nombreSeries: nombreSeries,
      repetitionsParSerie: repetitionsParSerie,
      tempsRepos: tempsRepos,
      notesPersonnalisees: notesPersonnalisees,
    );
    
    await _db.insertPlanExerciseAssignment(assignment);
  }

  /// Récupère les exercices d'un plan
  Future<List<PlanExerciseAssignment>> getPlanExercises(int planId) async {
    return await _db.getPlanExerciseAssignmentsByPlan(planId);
  }

  /// Met à jour un plan d'exercices
  Future<void> updateExercisePlan(ExercisePlan plan) async {
    await _db.updateExercisePlan(plan);
  }

  /// Supprime un plan d'exercices
  Future<void> deleteExercisePlan(int planId) async {
    await _db.deleteExercisePlan(planId);
  }

  // --- User Plan Assignment ---

  /// Assigne un plan à un utilisateur
  Future<UserPlanAssignment> assignPlanToUser({
    required int utilisateurId,
    required int planId,
    String? messageCoach,
    BuildContext? context,
  }) async {
    final assignment = UserPlanAssignment(
      utilisateurId: utilisateurId,
      planId: planId,
      dateAttribution: DateTime.now(),
      messageCoach: messageCoach,
    );
    
    final assignmentId = await _db.insertUserPlanAssignment(assignment);
    assignment.id = assignmentId;
    
    // Afficher une notification si le contexte est fourni
    if (context != null) {
      final plan = await getPlanById(planId);
      final user = await _db.getUtilisateurById(utilisateurId);
      if (plan != null && user != null) {
        NotificationService.showNewPlanNotification(
          context,
          assignment,
          plan,
          user,
        );
      }
    }
    
    return assignment;
  }

  /// Récupère les plans assignés à un utilisateur
  Future<List<UserPlanAssignment>> getUserPlans(int utilisateurId) async {
    return await _db.getUserPlanAssignmentsByUser(utilisateurId);
  }

  /// Récupère les utilisateurs d'un plan
  Future<List<UserPlanAssignment>> getPlanUsers(int planId) async {
    return await _db.getUserPlanAssignmentsByPlan(planId);
  }

  /// Démarre un plan pour un utilisateur
  Future<void> startUserPlan(int assignmentId, int utilisateurId) async {
    final assignments = await _db.getUserPlanAssignmentsByUser(utilisateurId);
    final assignment = assignments.firstWhere((a) => a.id == assignmentId);
    assignment.demarrerPlan();
    await _db.updateUserPlanAssignment(assignment);
  }

  /// Met à jour la progression d'un utilisateur
  Future<void> updateUserProgress(int assignmentId, int utilisateurId, int progression) async {
    final assignments = await _db.getUserPlanAssignmentsByUser(utilisateurId);
    final assignment = assignments.firstWhere((a) => a.id == assignmentId);
    assignment.mettreAJourProgression(progression);
    await _db.updateUserPlanAssignment(assignment);
  }

  // --- Exercise Session Management ---

  /// Démarre une séance d'exercice
  Future<ExerciseSession> startExerciseSession({
    required int planId,
    required int exerciseId,
    required int utilisateurId,
    required int nombreSeries,
    required int repetitionsParSerie,
    required int tempsRepos,
    String? notesCoach,
  }) async {
    final session = ExerciseSession(
      planId: planId,
      exerciseId: exerciseId,
      utilisateurId: utilisateurId,
      nombreSeries: nombreSeries,
      repetitionsParSerie: repetitionsParSerie,
      tempsRepos: tempsRepos,
      notesCoach: notesCoach,
    );
    
    session.demarrerSession();
    final sessionId = await _db.insertExerciseSession(session);
    session.id = sessionId;
    return session;
  }

  /// Termine une séance d'exercice
  Future<void> completeExerciseSession({
    required int sessionId,
    int? difficulte,
    String? commentaireUtilisateur,
    int? caloriesBrulees,
    BuildContext? context,
  }) async {
    final sessions = await _db.getExerciseSessionsByUser(0);
    final session = sessions.firstWhere((s) => s.id == sessionId);
    
    session.terminerSession();
    session.difficulte = difficulte;
    session.commentaireUtilisateur = commentaireUtilisateur;
    session.caloriesBrulees = caloriesBrulees;
    
    await _db.updateExerciseSession(session);
    
    // Afficher une notification si le contexte est fourni
    if (context != null && session.dureeReelle != null) {
      NotificationService.showWorkoutCompletedNotification(
        context,
        'Séance d\'exercice', // TODO: Récupérer le nom du plan
        session.dureeReelle!,
        caloriesBrulees ?? 0,
      );
    }
  }

  /// Récupère les séances d'un utilisateur
  Future<List<ExerciseSession>> getUserSessions(int utilisateurId) async {
    return await _db.getExerciseSessionsByUser(utilisateurId);
  }

  /// Récupère les séances d'un plan
  Future<List<ExerciseSession>> getPlanSessions(int planId) async {
    return await _db.getExerciseSessionsByPlan(planId);
  }

  /// Récupère les séances d'un utilisateur pour un plan spécifique
  Future<List<ExerciseSession>> getExerciseSessionsByUserAndPlan(int utilisateurId, int planId) async {
    return await _db.getExerciseSessionsByUserAndPlan(utilisateurId, planId);
  }

  /// Récupère les séances en cours d'un utilisateur
  Future<List<ExerciseSession>> getActiveUserSessions(int utilisateurId) async {
    final sessions = await _db.getExerciseSessionsByUser(utilisateurId);
    return sessions.where((s) => s.estEnCours()).toList();
  }

  // --- Statistics and Reports ---

  /// Calcule les statistiques d'un utilisateur
  Future<Map<String, dynamic>> getUserStats(int utilisateurId) async {
    final sessions = await _db.getExerciseSessionsByUser(utilisateurId);
    final completedSessions = sessions.where((s) => s.estTerminee).toList();
    
    final totalCalories = completedSessions
        .map((s) => s.caloriesBrulees ?? 0)
        .fold(0, (sum, calories) => sum + calories);
    
    final totalDuration = completedSessions
        .map((s) => s.dureeReelle ?? 0)
        .fold(0, (sum, duration) => sum + duration);
    
    final averageDifficulty = completedSessions.isNotEmpty
        ? completedSessions
            .map((s) => s.difficulte ?? 0)
            .fold(0, (sum, diff) => sum + diff) / completedSessions.length
        : 0.0;
    
    return {
      'totalSessions': completedSessions.length,
      'totalCalories': totalCalories,
      'totalDuration': totalDuration,
      'averageDifficulty': averageDifficulty,
      'lastSession': completedSessions.isNotEmpty ? completedSessions.first.dateFin : null,
    };
  }

  /// Génère un rapport de progression pour un coach
  Future<Map<String, dynamic>> getCoachReport(int coachId) async {
    final plans = await _db.getExercisePlansByCoach(coachId);
    final allSessions = <ExerciseSession>[];
    
    for (final plan in plans) {
      final sessions = await _db.getExerciseSessionsByPlan(plan.id!);
      allSessions.addAll(sessions);
    }
    
    final completedSessions = allSessions.where((s) => s.estTerminee).toList();
    final activeUsers = <int>{};
    
    for (final session in completedSessions) {
      activeUsers.add(session.utilisateurId);
    }
    
    return {
      'totalPlans': plans.length,
      'totalSessions': completedSessions.length,
      'activeUsers': activeUsers.length,
      'totalCalories': completedSessions
          .map((s) => s.caloriesBrulees ?? 0)
          .fold(0, (sum, calories) => sum + calories),
    };
  }

  // --- Data Initialization ---

  /// Initialise des exercices de démonstration
  Future<void> initializeDemoExercises() async {
    final existingExercises = await _db.getAllExercises();
    if (existingExercises.isNotEmpty) return;

    final demoExercises = [
      Exercise(
        nom: 'Pompes',
        description: 'Exercice de musculation pour les bras et la poitrine',
        type: 'musculation',
        partieCorps: 'bras, poitrine',
        niveau: 'débutant',
        objectif: 'gain musculaire, tonification',
        materiel: 'aucun',
        dureeEstimee: 10,
        caloriesEstimees: 8,
        instructions: 'Placez vos mains à plat sur le sol, alignées avec vos épaules. Descendez votre corps en pliant les bras, puis remontez.',
      ),
      Exercise(
        nom: 'Squats',
        description: 'Exercice pour renforcer les jambes et les fessiers',
        type: 'musculation',
        partieCorps: 'jambes, fessiers',
        niveau: 'débutant',
        objectif: 'gain musculaire, tonification',
        materiel: 'aucun',
        dureeEstimee: 15,
        caloriesEstimees: 6,
        instructions: 'Tenez-vous debout, pieds écartés de la largeur des épaules. Descendez en pliant les genoux, puis remontez.',
      ),
      Exercise(
        nom: 'Course sur place',
        description: 'Exercice cardio pour améliorer l\'endurance',
        type: 'cardio',
        partieCorps: 'jambes',
        niveau: 'débutant',
        objectif: 'perte de poids, endurance',
        materiel: 'aucun',
        dureeEstimee: 20,
        caloriesEstimees: 12,
        instructions: 'Courez sur place en levant les genoux alternativement. Maintenez un rythme régulier.',
      ),
      Exercise(
        nom: 'Planche',
        description: 'Exercice isométrique pour renforcer le tronc',
        type: 'musculation',
        partieCorps: 'abdos, dos',
        niveau: 'intermédiaire',
        objectif: 'tonification, gain musculaire',
        materiel: 'aucun',
        dureeEstimee: 5,
        caloriesEstimees: 4,
        instructions: 'Placez-vous en position de pompe, mais appuyez-vous sur les avant-bras. Maintenez la position.',
      ),
      Exercise(
        nom: 'Étirements du dos',
        description: 'Exercices de mobilité pour assouplir le dos',
        type: 'mobilité',
        partieCorps: 'dos',
        niveau: 'débutant',
        objectif: 'mobilité, récupération',
        materiel: 'aucun',
        dureeEstimee: 10,
        caloriesEstimees: 2,
        instructions: 'Asseyez-vous et penchez-vous en avant pour étirer le dos. Maintenez la position.',
      ),
    ];

    for (final exercise in demoExercises) {
      await _db.insertExercise(exercise);
    }
  }
}
