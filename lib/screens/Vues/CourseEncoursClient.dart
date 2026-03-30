import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../HomeV2/HomeV2.dart';

class EcranCourseEnCoursClient extends StatefulWidget {
  final String courseId;

  const EcranCourseEnCoursClient({
    super.key,
    required this.courseId,
  });

  @override
  State<StatefulWidget> createState() => _EcranCourseEnCoursClientState();
}

class _EcranCourseEnCoursClientState extends State<EcranCourseEnCoursClient> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;
  String? _error;

  Timer? _infoWindowTimer;
  Timer? _statusTimer;
  RealtimeChannel? _userChannel;
  String? _chauffeurId;
  BitmapDescriptor? carIcon;
  RealtimeChannel? _statusChannel;

  final PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];

  @override
  void initState() {
    super.initState();
    _startStatusWatcher();
    _loadCarIcon().then((_) {
      _loadCourseData();
    });
  }

  @override
  void dispose() {
    _infoWindowTimer?.cancel();
    _statusTimer?.cancel();
    _userChannel?.unsubscribe();
    _statusChannel?.unsubscribe();
    super.dispose();
  }


  Future<List<LatLng>> getOsrmRoute(LatLng start, LatLng end) async {
    final url =
        "https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final coords =
      json['routes'][0]['geometry']['coordinates'] as List<dynamic>;

      return coords
          .map((c) => LatLng(c[1] as double, c[0] as double))
          .toList();
    } else {
      throw Exception("Erreur OSRM: ${response.statusCode}");
    }
  }
  /// 🔹 Récupérer les infos de la course + l'id du chauffeur
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

      _chauffeurId = course['chauffeur__id'];

      LatLng? chauffeurPos;
      if (_chauffeurId != null) {
        // 🔹 Récupérer la position + infos chauffeur
        final user = await Supabase.instance.client
            .from('User')
            .select('latitude, longitude, nom, numero_telephone')
            .eq('id', _chauffeurId!)
            .maybeSingle();

        if (user != null) {
          chauffeurPos = LatLng(
            (user['latitude'] as num).toDouble(),
            (user['longitude'] as num).toDouble(),
          );

          // 🔹 Récupérer le véhicule du chauffeur (s’il existe)
          final vehicule = await Supabase.instance.client
              .from('Vehicule')
              .select('marque, numero_plaque')
              .eq('user_id', _chauffeurId!)
              .maybeSingle();

          String infoTitle = user['nom'] ?? 'Chauffeur';
          String infoSnippet = '';

          if (vehicule != null) {
            infoSnippet =
            'Véhicule: ${vehicule['marque'] ?? ''} ''}\n'
                'Plaque: ${vehicule['numero_plaque'] ?? ''}\n'
                'Tel: ${user['numero_telephone'] ?? ''}';
          } else {
            infoSnippet = 'Tel: ${user['numero_telephone'] ?? ''}';
          }

          _markers.add(
            Marker(
              markerId: const MarkerId('Chauffeur'),
              position: chauffeurPos,
              icon: carIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(
                title: infoTitle,
                snippet: infoSnippet,
                onTap: () {
                  _appelerChauffeur(); // 👈 Appel direct si on clique
                },
              ),
            ),
          );
        }
      }

      // 🔹 Marqueurs
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
            position: chauffeurPos,
            icon: carIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: 'Chauffeur'),
          ),
        );
      }

      // 🔹 Polylines avec OSRM
      final List<Polyline> polylines = [];

      // chauffeur -> client
      if (chauffeurPos != null) {
        final pointsChauffeurClient = await getOsrmRoute(chauffeurPos, departPos);
        polylines.add(
          Polyline(
            polylineId: const PolylineId("trajet_chauffeur_client"),
            points: pointsChauffeurClient,
            width: 5,
            color: Colors.red,
          ),
        );
      }

      // client -> destination
      final pointsClientDest = await getOsrmRoute(departPos, arriveePos);
      polylines.add(
        Polyline(
          polylineId: const PolylineId("trajet_client_destination"),
          points: pointsClientDest,
          width: 5,
          color: Colors.green,
        ),
      );

      setState(() {
        _markers = markers;
        _polylines = polylines.toSet();
        _loading = false;
      });

      if (_chauffeurId != null) {
        _listenToChauffeurPositions(_chauffeurId!);
      }
    } catch (e) {
      setState(() {
        _error = "Erreur: $e";
        _loading = false;
      });
    }
  }



  Future<void> _loadCarIcon() async {
    carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(58, 58)),
      'assets/icons/originale_Taxi.png',
    );
  }

  Future<String?> _getNumeroChauffeur() async {
    if (_chauffeurId == null) return null;

    try {
      final chauffeur = await Supabase.instance.client
          .from('User')
          .select('numero_telephone') // nom exact du champ
          .eq('id', _chauffeurId!)
          .maybeSingle();

      return chauffeur?['numero_telephone'] as String?;
    } catch (e) {
      debugPrint("Erreur récupération numéro chauffeur : $e");
      return null;
    }
  }

  Future<void> _appelerChauffeur() async {
    final numero = await _getNumeroChauffeur();

    if (numero == null || numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Numéro du chauffeur introuvable")),
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


  void _listenToChauffeurPositions(String chauffeurId) {
    _userChannel = Supabase.instance.client.channel('user_positions');

    _userChannel!.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'User',
        filter: 'id=eq.$chauffeurId',
      ),
          (payload, [ref]) {
        final newRecord = payload['new'];
        if (newRecord == null) return;

        final lat = (newRecord['latitude'] as num?)?.toDouble();
        final lng = (newRecord['longitude'] as num?)?.toDouble();

        if (lat == null || lng == null) return;

        final newPos = LatLng(lat, lng);

        debugPrint("📡 Nouvelle position chauffeur : $newPos");

        // 🔹 Mettre à jour le marqueur chauffeur
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

        // 🔹 Supprimer l’ancien polyline
        setState(() {
          _polylines.removeWhere(
                  (p) => p.polylineId.value == "trajet_chauffeur_client");
        });

        // 🔹 Récupérer le marker du client
        final clientMarker = _markers.firstWhere(
                (m) => m.markerId.value == "Client",
            orElse: () => Marker(markerId: const MarkerId("Client"), position: newPos));

        // 🔹 recalcul OSRM (asynchrone, hors setState)
        getOsrmRoute(newPos, clientMarker.position).then((points) {
          if (!mounted) return;
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId("trajet_chauffeur_client"),
                points: points,
                width: 5,
                color: Colors.red,
              ),
            );
          });
        });
      },
    );

    _userChannel!.subscribe();
  }


  /// 🔹 Vérifier si la course est annulée

  void _startStatusWatcher() {
    _statusChannel = Supabase.instance.client.channel('public:Course');

    _statusChannel!.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'Course',
        filter: 'id=eq.${widget.courseId}',
      ),
          (payload, [ref]) async {
        final newRecord = payload['new'];
        if (newRecord == null) return;

        final statut = newRecord['statut'] as String?;
        final clientId = newRecord['client__id'] as String?;

        if (statut == 'annulée' && clientId != null) {
          // Désabonner pour ne plus recevoir d'évènements
          _statusChannel?.unsubscribe();

          // récupérer les infos user
          final user = await Supabase.instance.client
              .from('User')
              .select('nom_utilisateur, numero_telephone')
              .eq('id', clientId)
              .maybeSingle();

          final username = user?['nom_utilisateur'] ?? '';
          final telephone = user?['numero_telephone'] ?? '';

          if (!mounted) return;

          // Afficher l'alerte
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
                        builder: (context) => HomeV2(
                          userId: clientId,
                          username: username,
                          telephone: telephone,
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

    _statusChannel!.subscribe();
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
          .update({'statut': 'annulée'})
          .eq('id', widget.courseId);

      if (!mounted) 
        Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'annulation : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cas : loading
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    // Cas : erreur
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Course en cours"),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(_error!)),
      );
    }

    // Cas : affichage map
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course en cours"),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await _annulerCourse();
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
        myLocationEnabled: false,       // 🔹 Affiche le point bleu du client
        myLocationButtonEnabled: false,
        zoomGesturesEnabled: true,
        zoomControlsEnabled: false,// 🔹 Bouton pour centrer sur le client
      ),
      floatingActionButton: Stack(
        children: [
          // 🔴 Bouton annuler course (large)
          Positioned(
            bottom: 20,
            left: 30,
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
              onPressed: _appelerChauffeur,
              backgroundColor: Colors.green,
              child: const Icon(Icons.call, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
