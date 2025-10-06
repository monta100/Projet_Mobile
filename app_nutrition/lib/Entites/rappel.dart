class Rappel {
  int? id;
  int? utilisateurId; // Relation avec Utilisateur
  String message;
  DateTime date;
  bool statut;

  Rappel({
    this.id,
    this.utilisateurId,
    required this.message,
    required this.date,
    this.statut = false,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'message': message,
      'date': date.toIso8601String(),
      'statut': statut ? 1 : 0, // SQLite utilise des entiers pour les booléens
    };
  }

  // Création d'un rappel depuis une Map
  factory Rappel.fromMap(Map<String, dynamic> map) {
    return Rappel(
      id: map['id'],
      utilisateurId: map['utilisateur_id'],
      message: map['message'],
      date: DateTime.parse(map['date']),
      statut: map['statut'] == 1, // Conversion entier vers booléen
    );
  }

  // Méthodes du diagramme UML

  /// Envoie une notification pour ce rappel
  void envoyerNotification() {
    if (!statut) {
      print('🔔 Notification envoyée: $message');
      print('📅 Date programmée: ${date.toLocal()}');
      // Ici on pourrait intégrer avec un service de notifications push
      // comme Firebase Cloud Messaging ou flutter_local_notifications
    } else {
      print('Rappel déjà traité: $message');
    }
  }

  /// Marque le rappel comme lu/traité
  void marquerCommeLu() {
    statut = true;
    print('Rappel marqué comme lu: $message');
  }

  /// Marque le rappel comme non lu
  void marquerCommeNonLu() {
    statut = false;
    print('Rappel marqué comme non lu: $message');
  }

  /// Vérifie si le rappel est dû maintenant
  bool estDu() {
    return DateTime.now().isAfter(date) && !statut;
  }

  /// Vérifie si le rappel est programmé pour aujourd'hui
  bool estAujourdhui() {
    final maintenant = DateTime.now();
    return date.year == maintenant.year &&
        date.month == maintenant.month &&
        date.day == maintenant.day;
  }

  /// Reporte le rappel à une nouvelle date
  void reporter(DateTime nouvelleDate) {
    date = nouvelleDate;
    statut = false; // Remettre comme non lu si reporté
    print('Rappel reporté au: ${nouvelleDate.toLocal()}');
  }

  /// Calcule le temps restant avant le rappel
  Duration tempsRestant() {
    return date.difference(DateTime.now());
  }

  @override
  String toString() {
    return 'Rappel{id: $id, message: $message, date: $date, statut: $statut}';
  }
}
