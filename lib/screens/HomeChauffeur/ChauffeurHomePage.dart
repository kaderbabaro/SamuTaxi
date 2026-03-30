import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rive_animation/screens/RecapitulatifCourseChauffeur.dart';
import 'package:rive_animation/screens/Vues/CourseEncoursChauffeur.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../Profil/Profil_edit.dart';
import '../Vues/AjouterVehicule.dart';
import '../Vues/Apropos.dart';

class ChauffeurHomePage extends StatefulWidget {
  final String userId;

  const ChauffeurHomePage({super.key, required this.userId});

  @override
  _ChauffeurHomePageState createState() => _ChauffeurHomePageState();
}

class _ChauffeurHomePageState extends State<ChauffeurHomePage> {
  GoogleMapController? _mapController;
  Timer? _timer;
  late RealtimeChannel _courseChannel;
  LatLng? _currentPosition;
  late Marker positionChauffeur;
  List<Map<String, dynamic>> _courses = [];
  final bool _isClientMode = false;
  final bool _hasVehicle = false;
  Map<String, bool> _loadingCourses = {};
  bool _isLoading = false;
  bool _locationDialogShown = false;
  StreamSubscription<ServiceStatus>? _locationServiceStream;
  late PanelController _panelController = PanelController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();


  @override
  void initState() {
    super.initState();

    // 🔹 Force la fermeture du clavier à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    _panelController = PanelController();

    _initNotificationsAndPermissions();
    _checkAndRequestLocation();
    _initRealtimeCourses();

    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchCourses());
  }

  Future<void> _initNotificationsAndPermissions() async {

    // Initialisation notifications
    const androidInit = AndroidInitializationSettings('logo_samutaxi');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_panelController.isPanelClosed) {
            _panelController.open();
          }
        });
      },
    );

    // Demande de permission notifications
    await _requestNotificationPermission();
    await _checkAndRequestLocation();
    await _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    // Vérifie si le service est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Activez la localisation pour continuer.")),
      );

      // Écoute l'état du service de localisation
      _locationServiceStream = Geolocator.getServiceStatusStream().listen((status) {
        if (status == ServiceStatus.enabled) {
          _getCurrentLocation();
          _locationServiceStream?.cancel(); // On arrête le stream pour éviter les appels répétés
        }
      });

      return;
    }
    // Vérifie la permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Récupère la position si tout est OK
    await _getCurrentLocation();
  }


  Future<void> _checkAndRequestLocation() async {
    // 1️⃣ Vérifie si le service de localisation est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled && !_locationDialogShown) {
      // 2️⃣ Marque qu’on a déjà montré le popup
      _locationDialogShown = true;

      // 3️⃣ Pop-up demandant d’activer la localisation
      if (!mounted) return;
      await _getCurrentLocation();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Localisation désactivée"),
          content: const Text(
            "Pour utiliser cette application, activez la localisation dans vos paramètres.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
              child: const Text("Activer"),
            ),
          ],
        ),
      );

      // 4️⃣ Après fermeture du pop-up → re-vérifie
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationDialogShown = false;
        return;
      }
    }
  }


  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestPermission();
      debugPrint("Permission notifications Android : $granted");
    }

    if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint("Permission notifications iOS : $granted");
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    Supabase.instance.client.removeChannel(_courseChannel);
    _locationServiceStream?.cancel();
    super.dispose();
  }


  void _initRealtimeCourses() {
    _courseChannel = Supabase.instance.client
        .channel('public:Course')
        .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'Course',
      ),
          (payload, [ref]) {
        _showNewCourseNotification(payload);
      },
    );
        _courseChannel.subscribe();
  }

  Future<void> _showNewCourseNotification(Map<String, dynamic> payload) async {
    final course = payload['new'];
    final courseId = course['id'];
    final arrivee = "${course['adresse_arrivee']}";

    const androidDetails = AndroidNotificationDetails(
      'new_course_channel',
      'Nouvelles courses',
      channelDescription: 'Notifications pour nouvelles courses disponibles',
      icon: 'logo_samutaxi',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      "Nouvelle course disponible 🚕",
      "Destination : $arrivee",
      notificationDetails,
      payload: courseId, // 🔹 on passe l'id de la course
    );
  }



  Future<void> _fetchCourses() async {
    final response = await Supabase.instance.client
        .from('Course')
        .select()
        .eq('statut', 'en attente')
        .order('created_at', ascending: false)
        .limit(10);

    setState(() {
      _courses = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<bool> chauffeurHasVehicle(String chauffeurId) async {
    final response = await Supabase.instance.client
        .from('Vehicule')
        .select()
        .eq('user_id', chauffeurId);

    return response.isNotEmpty;
  }

  Future<void> _accepterCourse(Map<String, dynamic> course) async {
    try {

      // 0️⃣ Vérifier si le chauffeur a un véhicule
      final vehicules = await Supabase.instance.client
          .from('Vehicule')
          .select()
          .eq('user_id', widget.userId)
          .limit(1) as List<dynamic>?;

      if (vehicules == null || vehicules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                "⚠️ Vous devez enregistrer un véhicule."),
          ),
        );
        return;
      }

      // 1️⃣ Vérifier que la localisation est activée
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "⚠️ Activez la localisation pour accepter la course.")),
        );
        return;
      }

      // 2️⃣ Vérifier et demander la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("⚠️ Permission de localisation refusée.")),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "⚠️ Permission refusée définitivement. Allez dans les paramètres.")),
        );
        return;
      }

      // 3️⃣ Récupérer la position actuelle du chauffeur
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final courseId = course['id'];

      final response = await Supabase.instance.client
          .from('Course')
          .update({
        'statut': 'acceptée',
        'chauffeur__id': widget.userId,
      })
          .eq('id', courseId)
          .select();

      if (response is List && response.isNotEmpty) {
        // 5️⃣ Mettre à jour la position du chauffeur
        await Supabase.instance.client
            .from('User')
            .update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'created_at': DateTime.now().toIso8601String(),
        })
            .eq('id', widget.userId);

        // 6️⃣ Mettre à jour l'UI
        setState(() {
          _courses.removeWhere((c) => c['id'] == courseId);
        });

        // 7️⃣ Message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Course acceptée et position mise à jour")),
        );

        // 8️⃣ Naviguer vers l'écran de course en cours
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EcranCourseEnCours(
              courseId: courseId,
              chauffeurId: widget.userId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Impossible d'accepter la course.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    }
  }


  Future<void> _detailscourse(Map<String, dynamic> course) async {
    final courseId = course['id'];

    final response = await Supabase.instance.client
        .from('Course')
        .select()
        .eq('id', courseId)
        .single();

    if (response != null) {
      setState(() {
        _courses.removeWhere((c) => c['id'] == courseId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚕 details de la course !")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecapitulatifCourseChauffeurPage(
            courseId: courseId,
            chauffeurId: widget.userId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Une erreur est survenue.")),
      );
    }
  }



  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      positionChauffeur = _currentPosition as Marker;
    });
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // Menu burger avec bottom sheet
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.directions_car, color: Colors.red),
                          title: const Text('Mon véhicule'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddVehiclePage(userId: widget.userId),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.red),
                          title: const Text('À propos'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.menu, color: Colors.red),
                ),
              ),
            ),

            // Profil utilisateur
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(userId: widget.userId),
                  ),
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator(backgroundColor: Colors.white, color: Colors.red,))
          : Stack(
        children: [
          GoogleMap(
            zoomGesturesEnabled: false,
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 60,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            panel: _buildPanelContent(),
            body: null,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.red.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Courses disponibles",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _courses.isEmpty
                ? const Center(child: Text("Aucune course disponible."))
                : ListView.builder(
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _detailscourse(course),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("De: ${course['adresse_depart']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("À: ${course['adresse_arrivee']}"),
                          const SizedBox(height: 4),
                          Text("Statut: ${course['statut']}"),
                          Text(
                            "Prix: ${course['prix'] != null ? '${course['prix']} FCFA' : 'Non défini'}",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _loadingCourses[course['id']] == true
                                      ? null
                                      : () async {
                                    setState(() => _loadingCourses[course['id']] = true);
                                    try {
                                      await _accepterCourse(course);
                                    } finally {
                                      if (mounted) setState(() => _loadingCourses[course['id']] = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: _loadingCourses[course['id']] == true
                                      ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text("Accepter"),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
