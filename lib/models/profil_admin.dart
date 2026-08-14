class ProfilAdmin {
  final String id;
  final String nom;
  final String email;
  final String role;

  ProfilAdmin({required this.id, required this.nom, required this.email, required this.role});

  factory ProfilAdmin.fromMap(Map<String, dynamic> map) {
    return ProfilAdmin(
      id: map['id'] as String,
      nom: map['nom'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
    );
  }
}