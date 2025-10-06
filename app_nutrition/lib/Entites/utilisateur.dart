class Utilisateur {
  int? id;
  String nom;
  String prenom;
  String email;
  String motDePasse;
  String role;

  Utilisateur({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    required this.role,
  });

  // Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': motDePasse,
      'role': role,
    };
  }

  // Création d'un utilisateur depuis une Map
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      email: map['email'],
      motDePasse: map['motDePasse'],
      role: map['role'],
    );
  }

  // Méthodes du diagramme UML
  
  /// Crée un profil utilisateur
  void creerProfil() {
    // Logique de création de profil
    print('Profil créé pour ${prenom} ${nom}');
  }

  /// Modifie le profil utilisateur
  void modifierProfil({
    String? nouveauNom,
    String? nouveauPrenom,
    String? nouvelEmail,
    String? nouveauRole,
  }) {
    if (nouveauNom != null) nom = nouveauNom;
    if (nouveauPrenom != null) prenom = nouveauPrenom;
    if (nouvelEmail != null) email = nouvelEmail;
    if (nouveauRole != null) role = nouveauRole;
    print('Profil modifié pour ${prenom} ${nom}');
  }

  /// Supprime le profil utilisateur
  void supprimerProfil() {
    print('Profil supprimé pour ${prenom} ${nom}');
  }

  /// Authentifie l'utilisateur
  bool seConnecter(String emailSaisi, String motDePasseSaisi) {
    return email == emailSaisi && motDePasse == motDePasseSaisi;
  }

  @override
  String toString() {
    return 'Utilisateur{id: $id, nom: $nom, prenom: $prenom, email: $email, role: $role}';
  }
}