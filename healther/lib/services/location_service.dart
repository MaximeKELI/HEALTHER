import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Vérifier les permissions de localisation
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Obtenir la position actuelle
  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await checkPermissions();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      return null;
    }
  }

  // Obtenir l'adresse à partir des coordonnées
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Construire l'adresse
        String address = '';
        if (place.street != null) address += place.street! + ', ';
        if (place.locality != null) address += place.locality! + ', ';
        if (place.administrativeArea != null) address += place.administrativeArea! + ', ';
        if (place.country != null) address += place.country!;
        
        return address.trim();
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'adresse: $e');
      return null;
    }
  }

  // Obtenir les informations de localisation complètes
  Future<Map<String, dynamic>?> getLocationInfo() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        return null;
      }

      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Extraire région et préfecture depuis l'adresse
      String? region;
      String? prefecture;

      if (address != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Pour le Togo, utiliser administrativeArea comme région
          region = place.administrativeArea;
          prefecture = place.subAdministrativeArea ?? place.locality;
        }
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'adresse': address,
        'region': region,
        'prefecture': prefecture,
      };
    } catch (e) {
      print('Erreur lors de la récupération des informations de localisation: $e');
      return null;
    }
  }
}


