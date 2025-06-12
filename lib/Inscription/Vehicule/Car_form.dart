
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:http/http.dart' as http;
import 'package:rive_animation/screens/onboding/onboding_screen.dart';
import '../../screens/entryPoint/entry_point.dart';
import '../../screens/onboding/components/sign_in_form.dart';

class CarForm extends StatefulWidget {
  const CarForm({Key? key}) : super(key: key);

  @override
  State<CarForm> createState() => _CarFormState();
}

class _CarFormState extends State<CarForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _couleurController = TextEditingController();
  final TextEditingController _numeroChassisController = TextEditingController();
  final TextEditingController _numeroPortiereController = TextEditingController();


  String? _selectedCapacity;
  String? _selectedEtat;

  late SMITrigger check;
  late SMITrigger error;
  late SMITrigger reset;
  late SMITrigger confetti;

  @override
  void dispose() {
    _matriculeController.dispose();
    _marqueController.dispose();
    _couleurController.dispose();
    _numeroChassisController.dispose();
    _numeroPortiereController.dispose();
    super.dispose();
  }

  bool isShowLoading = false;
  bool isShowConfetti = false;

  StateMachineController getRiveController(Artboard artboard) {
    StateMachineController? controller =
    StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    return controller;
  }

  void signIn(BuildContext context) async {
    setState(() {
      isShowLoading = true;
      isShowConfetti = true;
    });

    if (_formKey.currentState!.validate()) {
      // Perform the upload
      await _uploadCarInfo();
    } else {
      // show error
      error.fire();
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          isShowLoading = false;
        });
      });
    }
  }

  Future<void> _uploadCarInfo() async {
    final url = Uri.parse('http://192.168.137.1:8000/api/vehicules'); // Update localhost with your local IP
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    final int iduser = arguments['id_chauffeur'];
    final formData = {
      'matricules': _matriculeController.text,
      'modele_marque': _marqueController.text,
      'capacite': _selectedCapacity,
      'couleur': _couleurController.text,
      'numero_chassis': _numeroChassisController.text,
      'etat': _selectedEtat,
      'numero_portiere': _numeroPortiereController.text,
      'user' : iduser
    };
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(formData),
      );

      if (response.statusCode == 201) {
        // Successful upload
        print('Car information uploaded successfully');
        check.fire();

        await Future.delayed(Duration(seconds: 2));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );

        setState(() {
          isShowLoading = false;
        });
        confetti.fire();
      } else {
        // Error during upload
        print('Error during upload: ${response.body}');
        error.fire();
        await Future.delayed(Duration(seconds: 2));
        setState(() {
          isShowLoading = false;
        });
      }
    } catch (e) {
      // Network error
      print('Network error: $e');
      error.fire();
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        isShowLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informations du véhicule',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Matricule",
                      style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _matriculeController,
                      decoration: InputDecoration(
                        hintText: "Ex: AK-5022",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le matricule';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Numéro de Châssis
                  const Text("Numéro de Châssis",
                      style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _numeroChassisController,
                      decoration: InputDecoration(
                        hintText: "Ex: LDLXCHLAA7J1110088",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le numéro de châssis';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Numéro de Portière
                  const Text("Numéro de Portière",
                      style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _numeroPortiereController,
                      decoration: InputDecoration(
                        hintText: "Ex: 4345",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le numéro de portière';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Modèle/Marque
                  const Text("Modèle/Marque",
                      style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _marqueController,
                      decoration: InputDecoration(
                        hintText: "Ex: Marque-Modèle",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le modèle/marque du véhicule';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Couleur
                  const Text("Couleur",
                      style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _couleurController,
                      decoration: InputDecoration(
                        hintText: "Saisir la couleur du véhicule",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir la couleur du véhicule';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Capacité
                  const Text("Capacité",
                      style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCapacity,
                      items: ['1', '3','5','7','9']
                          .map((label) => DropdownMenuItem(
                        child: Text(label),
                        value: label,
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCapacity = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Sélectionner la capacité du véhicule",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner la capacité du véhicule';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // État
                  const Text("État", style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedEtat,
                      items: ['Neuf', 'Occasion']
                          .map((label) => DropdownMenuItem(
                        child: Text(label),
                        value: label,
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEtat = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Sélectionner l'état du véhicule",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner l\'état du véhicule';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouton Soumettre
                  Center(
                    child: ElevatedButton(
                      onPressed: () => signIn(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                        EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        'Continuer',
                        style: TextStyle(color: Colors.white,fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          isShowLoading
              ? CustomPositioned(
            child: RiveAnimation.asset(
              "assets/RiveAssets/check.riv",
              onInit: (artboard) {
                StateMachineController controller =
                getRiveController(artboard);
                check = controller.findSMI("Check") as SMITrigger;
                error = controller.findSMI("Error") as SMITrigger;
                reset = controller.findSMI("Reset") as SMITrigger;
                confetti = controller.findSMI("Confetti") as SMITrigger;
              },
            ),
          )
              : SizedBox(),
        ],
      ),
    );
  }
}
