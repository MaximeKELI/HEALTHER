enum MaladieType {
  paludisme,
  typhoide,
  mixte,
}

enum StatutDiagnostic {
  positif,
  negatif,
  incertain,
}

class Diagnostic {
  final int? id;
  final int userId;
  final MaladieType maladieType;
  final String? imagePath;
  final String? imageBase64;
  final Map<String, dynamic>? resultatIa;
  final double? confiance;
  final StatutDiagnostic statut;
  final double? quantiteParasites;
  final String? commentaires;
  final double? latitude;
  final double? longitude;
  final String? adresse;
  final String? region;
  final String? prefecture;
  final DateTime? createdAt;

  Diagnostic({
    this.id,
    required this.userId,
    required this.maladieType,
    this.imagePath,
    this.imageBase64,
    this.resultatIa,
    this.confiance,
    required this.statut,
    this.quantiteParasites,
    this.commentaires,
    this.latitude,
    this.longitude,
    this.adresse,
    this.region,
    this.prefecture,
    this.createdAt,
  });

  factory Diagnostic.fromJson(Map<String, dynamic> json) {
    return Diagnostic(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      maladieType: _parseMaladieType(json['maladie_type'] as String),
      imagePath: json['image_path'] as String?,
      imageBase64: json['image_base64'] as String?,
      resultatIa: json['resultat_ia'] != null
          ? (json['resultat_ia'] is Map
              ? json['resultat_ia'] as Map<String, dynamic>
              : {})
          : null,
      confiance: json['confiance'] != null
          ? (json['confiance'] as num).toDouble()
          : null,
      statut: _parseStatut(json['statut'] as String),
      quantiteParasites: json['quantite_parasites'] != null
          ? (json['quantite_parasites'] as num).toDouble()
          : null,
      commentaires: json['commentaires'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      adresse: json['adresse'] as String?,
      region: json['region'] as String?,
      prefecture: json['prefecture'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'maladie_type': maladieType.name,
      'image_path': imagePath,
      'image_base64': imageBase64,
      'resultat_ia': resultatIa,
      'confiance': confiance,
      'statut': statut.name,
      'quantite_parasites': quantiteParasites,
      'commentaires': commentaires,
      'latitude': latitude,
      'longitude': longitude,
      'adresse': adresse,
      'region': region,
      'prefecture': prefecture,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static MaladieType _parseMaladieType(String? type) {
    switch (type) {
      case 'paludisme':
        return MaladieType.paludisme;
      case 'typhoide':
        return MaladieType.typhoide;
      case 'mixte':
        return MaladieType.mixte;
      default:
        return MaladieType.paludisme;
    }
  }

  static StatutDiagnostic _parseStatut(String? statut) {
    switch (statut) {
      case 'positif':
        return StatutDiagnostic.positif;
      case 'negatif':
        return StatutDiagnostic.negatif;
      case 'incertain':
        return StatutDiagnostic.incertain;
      default:
        return StatutDiagnostic.negatif;
    }
  }

  String get maladieTypeLabel {
    switch (maladieType) {
      case MaladieType.paludisme:
        return 'Paludisme';
      case MaladieType.typhoide:
        return 'Fièvre Typhoïde';
      case MaladieType.mixte:
        return 'Mixte';
    }
  }

  String get statutLabel {
    switch (statut) {
      case StatutDiagnostic.positif:
        return 'Positif';
      case StatutDiagnostic.negatif:
        return 'Négatif';
      case StatutDiagnostic.incertain:
        return 'Incertain';
    }
  }
}


