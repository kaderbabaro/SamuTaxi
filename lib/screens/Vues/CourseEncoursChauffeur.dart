import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rive_animation/screens/HomeChauffeur/ChauffeurHomePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EcranCourseEnCours extends StatefulWidget {
  final String courseId;
  final String? chauffeurId;

  const EcranCourseEnCours({
    super.key,
    required this.courseId,
    this.chauffeurId,
  });

  @override
  State<StatefulWidget> createState() => _EcranCourseEnCoursState();
}

class _EcranCourseEnCoursState extends State<EcranCourseEnCours> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;
  String? _error;
  Timer? _infoWindowTimer;
  Timer? _statusTimer;
  Timer? _positionTimer;
  late RealtimeChannel _userChannel;
  RealtimeChannel? _courseChannel;

  BitmapDescriptor? carIcon;

  @override
  void initState() {
    super.initState();
    _startStatusSubscription();
    _loadCourseData();
    _startPositionUpdates();
    _listenToPositions();
    _loadCarIcon();
  }

  @override
  void dispose() {
    _infoWindowTimer?.cancel();
    _statusTimer?.cancel();
    _positionTimer?.cancel();
    _userChannel.unsubscribe();
    _courseChannel?.unsubscribe();

    super.dispose();
  }

  void _startStatusSubscription() {
    // On s'abonne à la ligne Course précise
    _courseChannel = Supabase.instance.client.channel('public:Course');

    _courseChannel!.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'Course',
        filter: 'id=eq.${widget.courseId}', // juste cette course
      ),
          (payload, [ref]) async {
        final newRecord = payload['new'];
        if (newRecord == null) return;

        final statut = newRecord['statut'] as String?;
        final chauffeurId = newRecord['chauffeur__id'] as String?;

        if (statut == 'annulée') {
          if (!mounted) return;

          // Facultatif : récupérer infos chauffeur
          Map<String, dynamic>? chauffeur;
          if (chauffeurId != null && chauffeurId.isNotEmpty) {
            chauffeur = await Supabase.instance.client
                .from('User')
                .select('nom_utilisateur, numero_telephone')
                .eq('id', chauffeurId)
                .maybeSingle();
          }

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Course annulée"),
              content: const Text("La course a été annulée."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => ChauffeurHomePage(
                          userId: chauffeurId ?? '',
                        ),
                      ),
                          (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      },
    );

    _courseChannel!.subscribe();
  }

  Future<void> _appelerClient() async {
    final numero = await _getNumeroClient();

    if (numero == null || numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Numéro du client introuvable")),
      );
      return;
    }

    final Uri telUri = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de passer l'appel")),
      );
    }
  }


  Future<String?> _getNumeroClient() async {
    try {
      final course = await Supabase.instance.client
          .from('Course')
          .select('client__id')
          .eq('id', widget.courseId)
          .maybeSingle();

      if (course == null) return null;

      final clientId = course['client__id'];
      if (clientId == null) return null;

      final client = await Supabase.instance.client
          .from('User')
          .select('numero_telephone') // ou le nom exact du champ
          .eq('id', clientId)
          .maybeSingle();

      return client?['numero_telephone'] as String?;
    } catch (e) {
      debugPrint("Erreur récupération numéro client : $e");
      return null;
    }
  }

  void _startPositionUpdates() {
    if (widget.chauffeurId == null) return;

    // Timer toutes les 5 secondes
    _positionTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        // 1️⃣ Vérifier que le service de localisation est activé
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint("⚠️ Service de localisation désactivé");
          return;
        }

        // 2️⃣ Vérifier et demander la permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            debugPrint("⚠️ Permission de localisation refusée");
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          debugPrint("⚠️ Permission refusée définitivement");
          return;
        }

        // 3️⃣ Récupérer la position actuelle
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );


        final response = await Supabase.instance.client
            .from('User')
            .update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'created_at': DateTime.now().toIso8601String(), // Vérifie le nom exact dans Supabase
        })
            .eq('id', widget.chauffeurId!);

        debugPrint("📍 Position chauffeur mise à jour : "
            "${position.latitude}, ${position.longitude}");
      } catch (e) {
        debugPrint("❌ Erreur mise à jour position chauffeur : $e");
      }
    });
  }

  Future<void> _loadCarIcon() async {
    carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(58, 58)),
      'assets/icons/originale_Taxi.png',
    );
  }

  void _listenToPositions() {
    if (widget.chauffeurId == null) return;

    _userChannel = Supabase.instance.client.channel('public:User');

    _userChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'User',
        filter: 'id=eq.${widget.chauffeurId!}',
      ),
          (payload, [ref]) async {
        final newRecord = payload['new'];
        if (newRecord == null) return;

        final lat = (newRecord['latitude'] as num?)?.toDouble();
        final lng = (newRecord['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) return;

        final newPos = LatLng(lat, lng);

        // 🔹 mettre à jour le marqueur
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == "Chauffeur");
          _markers.add(
            Marker(
              markerId: const MarkerId("Chauffeur"),
              position: newPos,
              icon: carIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(title: "Chauffeur"),
            ),
          );
        });

        // 🔹 récupérer le marker client
        final clientMarker = _markers.firstWhere(
              (m) => m.markerId.value == "Client",
          orElse: () =>
          const Marker(markerId: MarkerId("Client"), position: LatLng(0, 0)),
        );

        // 🔹 recalculer l’itinéraire via OSRM
        final routePoints = await getOsrmRoute(newPos, clientMarker.position);

        if (!mounted) return;
        setState(() {
          _polylines.removeWhere(
                  (p) => p.polylineId.value == "trajet_chauffeur_client");
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("trajet_chauffeur_client"),
              points: routePoints,
              width: 5,
              color: Colors.red,
            ),
          );
        });

        debugPrint("📡 Nouvelle position chauffeur : $lat, $lng");
      },
    );

    _userChannel.subscribe();
  }



  Future<void> _loadCourseData() async {
    try {
      final course = await Supabase.instance.client
          .from('Course')
          .select(
          'latitude_depart, longitude_depart, latitude_arrivee, longitude_arrivee, chauffeur__id')
          .eq('id', widget.courseId)
          .maybeSingle();

      if (course == null) throw "Course introuvable";

      LatLng departPos = LatLng(
        (course['latitude_depart'] as num).toDouble(),
        (course['longitude_depart'] as num).toDouble(),
      );
      LatLng arriveePos = LatLng(
        (course['latitude_arrivee'] as num).toDouble(),
        (course['longitude_arrivee'] as num).toDouble(),
      );

      String? idChauffeur = widget.chauffeurId ?? course['chauffeur__id'];
      LatLng? chauffeurPos;

      final user = await Supabase.instance.client
          .from('User')
          .select('latitude, longitude')
          .eq('id', idChauffeur)
          .maybeSingle();

      if (user != null) {
        chauffeurPos = LatLng(
          (user['latitude'] as num).toDouble(),
          (user['longitude'] as num).toDouble(),
        );
      }
    
      Set<Marker> markers = {
        Marker(
          markerId: const MarkerId('Client'),
          position: departPos,
          infoWindow: const InfoWindow(title: 'Client'),
        ),
        Marker(
          markerId: const MarkerId('Destination'),
          position: arriveePos,
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      };

      if (chauffeurPos != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('Chauffeur'),
            icon: carIcon ?? BitmapDescriptor.defaultMarker,
            position: chauffeurPos,
            infoWindow: const InfoWindow(title: 'Chauffeur'),
          ),
        );
      }

      Set<Polyline> polylines = {};
      if (chauffeurPos != null) {
        final routePoints = await getOsrmRoute(chauffeurPos, departPos);
        polylines.add(
          Polyline(
            polylineId: const PolylineId("trajet_chauffeur_client"),
            points: routePoints, // ⬅️ points de la route OSRM
            width: 5,
            color: Colors.red,
          ),
        );
      }

      final routeClientDest = await getOsrmRoute(departPos, arriveePos);
      polylines.add(
        Polyline(
          polylineId: const PolylineId("trajet_client_destination"),
          points: routeClientDest,
          width: 5,
          color: Colors.green,
        ),
      );

      setState(() {
        _markers = markers;
        _polylines = polylines;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erreur: $e";
        _loading = false;
      });
    }
  }

  Future<List<LatLng>> getOsrmRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson'
    );
    final res = await http.get(url);
    final data = json.decode(res.body);

    final coords = data['routes'][0]['geometry']['coordinates'] as List;
    return coords.map((c) => LatLng(c[1], c[0])).toList();
  }

  void _startInfoWindowCycle() {
    final ids = _markers.map((m) => m.markerId).toList();
    if (ids.isEmpty) return;

    int index = 0;
    _infoWindowTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final current = ids[index % ids.length];
      final previous = ids[(index - 1 + ids.length) % ids.length];

      _mapController?.hideMarkerInfoWindow(previous);
      _mapController?.showMarkerInfoWindow(current);

      index++;
    });
  }

  void _zoomToFitMarkers() {
    if (_markers.isEmpty) return;

    final lats = _markers.map((m) => m.position.latitude).toList();
    final lngs = _markers.map((m) => m.position.longitude).toList();

    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce(min), lngs.reduce(min)),
      northeast: LatLng(lats.reduce(max), lngs.reduce(max)),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Future<void> _annulerCourse() async {
    try {
      await Supabase.instance.client
          .from('Course')
          .update({
        'statut': 'annulée',
        'chauffeur__id': widget.chauffeurId,
      })
          .eq('id', widget.courseId);

      if (!mounted) return;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'annulation : $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Cas : Loading
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    // Cas : Erreur
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Course en cours"),
          backgroundColor: Colors.red,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _mettreAJourCourseAnnulee();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(child: Text(_error!)),
      );
    }

    // Cas : Map + markers
    return WillPopScope(
      onWillPop: () async {
        await _mettreAJourCourseAnnulee();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Course en cours"),
          backgroundColor: Colors.red,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _annulerCourse();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _markers.isNotEmpty ? _markers.first.position : const LatLng(0, 0),
            zoom: 14,
          ),
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (controller) {
            _mapController = controller;
            _zoomToFitMarkers();
            _startInfoWindowCycle();
          },
          myLocationEnabled: false, // 🔹 Point bleu
          myLocationButtonEnabled: false,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: false,
        ),
        floatingActionButton: Stack(
          children: [
            // 🔴 Bouton annuler course (large)
            Positioned(
              bottom: 20,
              left: 20,
              right: 70,
              child: SizedBox(
                height: 50,
                child: FloatingActionButton.extended(
                  onPressed: _annulerCourse,
                  label: const Text("Annuler la course",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
            // 🟢 Bouton appeler chauffeur (juste icone)
            Positioned(
              bottom: 20,
              right: 10,
              child: FloatingActionButton(
                onPressed: _appelerClient,
                backgroundColor: Colors.green,
                child: const Icon(Icons.call, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }


// Fonction pour mettre à jour la course comme annulée dans Supabase
  Future<void> _mettreAJourCourseAnnulee() async {
    try {
      await Supabase.instance.client
          .from('Course')
          .update({
        'statut': 'annulée',
        'chauffeur__id': widget.chauffeurId,
      })
          .eq('id', widget.courseId);
      debugPrint("Course mise à jour comme annulée car l'utilisateur est retourné.");
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour de la course : $e");
    }
  }

}
