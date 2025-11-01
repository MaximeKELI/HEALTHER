class User {
  final int? id;
  final String username;
  final String email;
  final String? nom;
  final String? prenom;
  final String? centreSante;
  final String role;
  final String? profilePicture;
  final String? profilePictureUrl;
  final DateTime? createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    this.nom,
    this.prenom,
    this.centreSante,
    this.role = 'agent',
    this.profilePicture,
    this.profilePictureUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nom: json['nom']?.toString(),
      prenom: json['prenom']?.toString(),
      centreSante: json['centre_sante']?.toString(),
      role: (json['role']?.toString() ?? 'agent').toLowerCase(),
      profilePicture: json['profile_picture']?.toString(),
      profilePictureUrl: json['profile_picture_url']?.toString(),
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'centre_sante': centreSante,
      'role': role,
      'profile_picture': profilePicture,
      'profile_picture_url': profilePictureUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? nom,
    String? prenom,
    String? centreSante,
    String? role,
    String? profilePicture,
    String? profilePictureUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      centreSante: centreSante ?? this.centreSante,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get fullName {
    if (nom != null && prenom != null) {
      return '$prenom $nom';
    } else if (prenom != null && prenom!.isNotEmpty) {
      return prenom!;
    } else if (nom != null && nom!.isNotEmpty) {
      return nom!;
    }
    return username;
  }
}


