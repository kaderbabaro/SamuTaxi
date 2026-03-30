import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rive_animation/screens/Vues/CourseEncoursChauffeur.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/Apiservices/DirectionAPIs.dart';

class RecapitulatifCourseChauffeurPage extends StatefulWidget {
  final String courseId;
  final String chauffeurId;

  const RecapitulatifCourseChauffeurPage({
    Key? key,
    required this.courseId, required this.chauffeurId,
  }) : super(key: key);

  @override
  State<RecapitulatifCourseChauffeurPage> createState() =>
      _RecapitulatifCourseChauffeurPageState();
}

class _RecapitulatifCourseChauffeurPageState
    extends State<RecapitulatifCourseChauffeurPage> {
  GoogleMapController? _mapController;

  Map<String, dynamic>? _course;     // données de la course
  bool _loading = true;              // état de chargement
  bool _locationDialogShown = false;
  String? _error;
  Timer? _statusTimer;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _startStatusWatcher();
    _loadCourse(widget.courseId);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusWatcher() {
    int errorCount = 0;

    _statusTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      try {
        final course = await Supabase.instance.client
            .from('Course')
            .select('statut')
            .eq('id', widget.courseId)
            .maybeSingle();

        if (course == null) return;

        final statut = course['statut'] as String?;

        if (statut == 'acceptée') {
          if (!mounted) return;
          _statusTimer?.cancel(); // stop le watcher
          if (Navigator.canPop(context)) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("La course a été acceptée par un autre Chauffeur"),
            ),
          );
        }

        // Reset compteur d'erreurs si tout va bien
        errorCount = 0;
      } catch (e, st) {
        errorCount++;
        debugPrint("Erreur lors du check du statut : $e\n$st");

        // Stop le timer si trop d'erreurs consécutives (ex: 5)
        if (errorCount >= 5) {
          _statusTimer?.cancel();
          debugPrint("Arrêt du watcher après 5 erreurs consécutives.");
        }
      }
    });
  }

  Future<void> _loadCourse(String id) async {
    try {
      final data = await Supabase.instance.client
          .from('Course')
          .select('id, adresse_depart, adresse_arrivee, prix, statut, '
          'latitude_depart, longitude_depart, latitude_arrivee, longitude_arrivee, '
          'type_taxi, moyen_paiement')
          .eq('id', id)
          .maybeSingle();

      if (data == null) {
        setState(() {
          _error = "❌ Course introuvable";
          _loading = false;
        });
        return;
      }

      print("📦 Données course : $data");

      final dLat = (data['latitude_depart'] as num?)?.toDouble();
      final dLng = (data['longitude_depart'] as num?)?.toDouble();
      final aLat = (data['latitude_arrivee'] as num?)?.toDouble();
      final aLng = (data['longitude_arrivee'] as num?)?.toDouble();

      if (dLat != null && dLng != null && aLat != null && aLng != null) {
        final routePoints = await getOsrmRoute(LatLng(dLat, dLng), LatLng(aLat, aLng));

        setState(() {
          _course = data;
          _markers = {
            Marker(markerId: const MarkerId('start'), position: LatLng(dLat, dLng),infoWindow: InfoWindow(title: "Client",snippet: _course?['addresse_depart'])),
            Marker(markerId: const MarkerId('dest'), position: LatLng(aLat, aLng),infoWindow: InfoWindow(title: "Destination",snippet: _course?['addresse_arrivee'])),
          };
          _polylines = {
            Polyline(
              polylineId: const PolylineId('trajet'),
              color: Colors.red,
              width: 5,
              points: routePoints,
            )
          };
          _loading = false;
        });
      } else {
        setState(() {
          _course = data;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "❌ Erreur : $e";
        _loading = false;
      });
    }
  }


  Future<void> _accepterCourse() async {
    try {
      // 1️⃣ Vérifier que la localisation est activée
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Activez la localisation pour accepter la course.")),
        );
        return;
      }

      // 2️⃣ Vérifier et demander la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Permission de localisation refusée.")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Permission refusée définitivement. Allez dans les paramètres.")),
        );
        return;
      }

      // 3️⃣ Récupérer la position actuelle du chauffeur
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4️⃣ Mettre à jour la course
      await Supabase.instance.client.from('Course').update({
        'statut': 'acceptée',
        'chauffeur__id': widget.chauffeurId,
      }).eq('id', widget.courseId);

      // 5️⃣ Mettre à jour la position du chauffeur
      await Supabase.instance.client.from('User').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }).eq('id', widget.chauffeurId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Course acceptée et position mise à jour")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EcranCourseEnCours(courseId: widget.courseId,chauffeurId: widget.chauffeurId,),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(backgroundColor: Colors.white,color: Colors.red,)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course à accepter'), backgroundColor: Colors.orange),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadCourse(widget.courseId),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback si carte impossible mais données présentes : on montre quand même le récap
    final hasCoords = _markers.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Course à accepter',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (hasCoords)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _markers.first.position,
                zoom: 12,
              ),
              onMapCreated: (c) {
                _mapController = c;

                // Liste des MarkerIds à afficher en alternance
                final markerIds = [const MarkerId('start'), const MarkerId('dest')];

                int index = 0;

                void showNextMarker() {
                  final current = markerIds[index % markerIds.length];
                  final previous = markerIds[(index - 1 + markerIds.length) % markerIds.length];
                  _mapController?.hideMarkerInfoWindow(previous);
                  _mapController?.showMarkerInfoWindow(current);

                  index++;
                  // Relancer après 2 secondes
                  Future.delayed(const Duration(seconds: 2), showNextMarker);
                }

                // Démarrer la boucle
                Future.delayed(const Duration(milliseconds: 300), showNextMarker);
              },
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            )
          else
            const Center(
              child: Text(
                'Pas de coordonnées à afficher.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 15,
                    color: Colors.black12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "De : ${_course?['adresse_depart'] ?? '-'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "À : ${_course?['adresse_arrivee'] ?? '-'}",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Statut : ${_course?['statut'] ?? '-'}",
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        _course?['prix'] != null
                            ? "${_course!['prix']} FCFA"
                            : "Non défini",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _accepterCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        "Accepter la course",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
