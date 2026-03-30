import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'CourseEncoursClient.dart';
import 'RecapitulatifCoursePage.dart';

class EcranRechercheChauffeur extends StatefulWidget {
  final String? clientId;
  final String depart;
  final String destination;
  final String modePaiement;
  final String typeTaxi;
  final double prixEstime;
  final LatLng departCoords;
  final LatLng destinationCoords;

  const EcranRechercheChauffeur({
    Key? key,
    required this.depart,
    required this.destination,
    required this.modePaiement,
    required this.typeTaxi,
    required this.prixEstime,
    required this.departCoords,
    required this.destinationCoords, required this.clientId,
  }) : super(key: key);

  @override
  State<EcranRechercheChauffeur> createState() => _EcranRechercheChauffeurState();
}

class _EcranRechercheChauffeurState extends State<EcranRechercheChauffeur> with WidgetsBindingObserver{
  bool _annule = false;
  int _tempsEcoule = 0;
  Timer? _timer;
  Timer? _checkStatusTimer;
  String? _courseId;
  bool _aDejaNavigue = false;
  double _enteredPrice = 0; // ou null si tu veux


  @override
  void initState() {
    super.initState();
    _enteredPrice = widget.prixEstime;
    WidgetsBinding.instance.addObserver(this);
    _envoyerCommandeAuServeur();

    _checkStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _verifierStatutCourse();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_annule) {
        timer.cancel();
      } else {
        setState(() {
          _tempsEcoule++;
        });

        if (_tempsEcoule >= 300) {
          timer.cancel();
          _annulerAutomatiquement();
          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) => RecapitulatifCoursePage(
                  depart: widget.depart,
                  destination: widget.destination,
                  modePaiement: widget.modePaiement,
                  typeTaxi: widget.typeTaxi,
                  prixEstime: widget.prixEstime,
                  departCoords: widget.departCoords,
                  destinationCoords: widget.destinationCoords
              )
          )
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // L'utilisateur a quitté l'app → annuler la course
      if (!_annule && _courseId != null) {
        _annulerAutomatiquement();
      }
    }
  }
  Future<void> _annulerAutomatiquement() async {
    try {
      await Supabase.instance.client
          .from('Course')
          .update({'statut': 'annulée'})
          .eq('id', _courseId);
      print('✅ Course annulée');
    } catch (e) {
      print('❌ Erreur annulation automatique : $e');
    }
  }


  void _annulerRecherche() async {
    if (_courseId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune course à annuler, veuillez ressayer")),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _annule = true;
    });

    try {
      await Supabase.instance.client
          .from('Course')
          .update({'statut': 'annulée'}) // Change seulement le statut
          .eq('id', _courseId);

      if (!mounted) return; // ✅ Vérification avant d’utiliser context
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⛔ Course annulée avec succès.")),
      );
    } catch (e) {
      print('❌ Erreur lors de l\'annulation : $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l’annulation : $e")),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }



  Future<void> _envoyerCommandeAuServeur() async {
    try {
      print("l'id du client:  ${widget.clientId}");
      final data = {
        'client__id': widget.clientId,
        'adresse_depart': widget.depart,
        'adresse_arrivee': widget.destination,
        'moyen_paiement': widget.modePaiement,
        'type_taxi': widget.typeTaxi,
        'prix': _enteredPrice.toInt(),
        'latitude_depart': widget.departCoords.latitude,
        'longitude_depart': widget.departCoords.longitude,
        'latitude_arrivee': widget.destinationCoords.latitude,
        'longitude_arrivee': widget.destinationCoords.longitude,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'statut': 'en attente',
      };

      final response = await Supabase.instance.client
          .from('Course')
          .insert(data)
          .select('id');

      print("📦 Réponse Supabase : $response");

      if (response != null && response.isNotEmpty) {
        final id = response[0]['id'];
        setState(() {
          _courseId = id?.toString(); // ✅ UUID correctement stocké
        });
        print('✅ ID de la course : $_courseId (type: ${_courseId.runtimeType})');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Course enregistrée avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ Réponse vide ou invalide.');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la commande : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l’envoi de la commande.")),
      );
    }
  }

  Future<void> _verifierStatutCourse() async {
    if (_courseId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('Course')
          .select('statut')
          .eq('id', _courseId)
          .maybeSingle();

      final statut = response?['statut'];

      if (statut == 'acceptée' && !_aDejaNavigue) {
        _aDejaNavigue = true;
        _timer?.cancel();
        _checkStatusTimer?.cancel();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EcranCourseEnCoursClient(
                courseId: _courseId!,
              ),
            ),
          );
        }
      }

      if (statut == 'annulée' && !_aDejaNavigue) {
        _aDejaNavigue = true;
        _timer?.cancel();
        _checkStatusTimer?.cancel();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "❌ délais écoulé: annulé la course",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );

          // ⏳ Attendre 3 sec avant de retourner à la page récapitulatif
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) => RecapitulatifCoursePage(
                  depart: widget.depart,
                  destination: widget.destination,
                  modePaiement: widget.modePaiement,
                  typeTaxi: widget.typeTaxi,
                  prixEstime: widget.prixEstime,
                  departCoords: widget.departCoords,
                  destinationCoords: widget.destinationCoords
                  )
                )
              );
            }
          });
        }
      }

    } catch (e) {
      print('❌ Erreur vérification statut : $e');
    }
  }

  void _proposerAugmentationPrix() {
    final double distance = _calculateDistanceKm(); // Crée cette fonction si elle n'existe pas
    final int suggestedPrice = _calculateSuggestedPrice(distance);
    final int minPrice = (suggestedPrice * 0.5).round();
    final int maxPrice = (suggestedPrice * 1.5).round();
    final TextEditingController priceController = TextEditingController(text: suggestedPrice.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Augmenter le prix"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Prix conseillé : $suggestedPrice F CFA"),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Votre prix (entre $minPrice et $maxPrice)",
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // fermer le dialogue
              },
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                int entered = int.tryParse(priceController.text) ?? suggestedPrice;
                if (entered < minPrice) entered = minPrice;
                if (entered > maxPrice) entered = maxPrice;

                setState(() {
                  // Mets à jour le prix
                  _enteredPrice = entered.toDouble(); // ou une variable locale si tu ne peux pas modifier widget
                });

                Navigator.pop(context); // fermer le dialogue

                _envoyerCommandeAuServeur();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white
              ),
              child: const Text("Valider"),
            ),
          ],
        );
      },
    );
  }

// Exemple de fonction pour calculer le prix conseillé
  int _calculateSuggestedPrice(double distance) {
    if (distance <= 3) return 200;
    double unit = 200 / 3;
    if (widget.typeTaxi == 'Privé') unit *= 3; // 3x le prix pour privé
    return (distance * unit).round();
  }

// Exemple pour calculer la distance en km entre départ et destination
  double _calculateDistanceKm() {
    if (widget.departCoords == null || widget.destinationCoords == null) return 0;
    return Geolocator.distanceBetween(
      widget.departCoords.latitude,
      widget.departCoords.longitude,
      widget.destinationCoords.latitude,
      widget.destinationCoords.longitude,
    ) / 1000;
  }


  @override
  void dispose() {
    _timer?.cancel();
    _checkStatusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 6,
              ),
              const SizedBox(height: 24),
              const Text(
                'Recherche d’un chauffeur...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('Temps écoulé : $_tempsEcoule s'),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _annulerRecherche,
                icon: const Icon(Icons.cancel),
                label: const Text('Annuler'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Message et bouton si temps > 60 secondes
              if (_tempsEcoule >= 60)
                Column(
                  children: [
                    const Text(
                      "⏳ Aucun chauffeur n'a accepté votre course. Vous pouvez augmenter le prix pour attirer un chauffeur.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Ici tu peux appeler un fonction pour proposer l'écran de modification du prix
                        _proposerAugmentationPrix();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Augmenter le prix"),
                    ),
                  ],
                ),
            ],
          )
        ),
      ),
    );
  }
}
