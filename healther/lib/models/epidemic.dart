enum NiveauAlerte {
  vert,
  jaune,
  orange,
  rouge,
}

enum StatutEpidemie {
  actif,
  resolu,
  surveille,
}

class Epidemic {
  final int? id;
  final String region;
  final String? prefecture;
  final String maladieType;
  final int nombreCas;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final StatutEpidemie statut;
  final NiveauAlerte? niveauAlerte;
  final String? actionsPrises;
  final DateTime? createdAt;

  Epidemic({
    this.id,
    required this.region,
    this.prefecture,
    required this.maladieType,
    required this.nombreCas,
    required this.dateDebut,
    this.dateFin,
    this.statut = StatutEpidemie.actif,
    this.niveauAlerte,
    this.actionsPrises,
    this.createdAt,
  });

  factory Epidemic.fromJson(Map<String, dynamic> json) {
    return Epidemic(
      id: json['id'] as int?,
      region: json['region'] as String,
      prefecture: json['prefecture'] as String?,
      maladieType: json['maladie_type'] as String,
      nombreCas: json['nombre_cas'] as int,
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: json['date_fin'] != null
          ? DateTime.parse(json['date_fin'] as String)
          : null,
      statut: _parseStatut(json['statut'] as String?),
      niveauAlerte: json['niveau_alerte'] != null
          ? _parseNiveauAlerte(json['niveau_alerte'] as String)
          : null,
      actionsPrises: json['actions_prises'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'prefecture': prefecture,
      'maladie_type': maladieType,
      'nombre_cas': nombreCas,
      'date_debut': dateDebut.toIso8601String().split('T')[0],
      'date_fin': dateFin?.toIso8601String().split('T')[0],
      'statut': statut.name,
      'niveau_alerte': niveauAlerte?.name,
      'actions_prises': actionsPrises,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static StatutEpidemie _parseStatut(String? statut) {
    switch (statut) {
      case 'actif':
        return StatutEpidemie.actif;
      case 'resolu':
        return StatutEpidemie.resolu;
      case 'surveille':
        return StatutEpidemie.surveille;
      default:
        return StatutEpidemie.actif;
    }
  }

  static NiveauAlerte _parseNiveauAlerte(String? niveau) {
    switch (niveau) {
      case 'vert':
        return NiveauAlerte.vert;
      case 'jaune':
        return NiveauAlerte.jaune;
      case 'orange':
        return NiveauAlerte.orange;
      case 'rouge':
        return NiveauAlerte.rouge;
      default:
        return NiveauAlerte.vert;
    }
  }

  String get niveauAlerteLabel {
    switch (niveauAlerte) {
      case NiveauAlerte.vert:
        return 'Vert';
      case NiveauAlerte.jaune:
        return 'Jaune';
      case NiveauAlerte.orange:
        return 'Orange';
      case NiveauAlerte.rouge:
        return 'Rouge';
      default:
        return 'Non défini';
    }
  }
}


