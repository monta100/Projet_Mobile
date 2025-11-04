
class Utilisateur {
  static const String tableName = 'utilisateurs';

  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;
  final String role;

  Utilisateur({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    required this.role,
  });

  Utilisateur copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? motDePasse,
    String? role,
  }) => Utilisateur(
    id: id ?? this.id,
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    email: email ?? this.email,
    motDePasse: motDePasse ?? this.motDePasse,
    role: role ?? this.role,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'mot_de_passe': motDePasse,
    'role': role,
  };

  factory Utilisateur.fromMap(Map<String, dynamic> map) => Utilisateur(
    id: map['id'] as int?,
    nom: map['nom'] as String,
    prenom: map['prenom'] as String,
    email: map['email'] as String,
    motDePasse: map['mot_de_passe'] as String,
    role: map['role'] as String,
  );

  
}
