import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:http/http.dart' as http;
import 'package:rive_animation/Inscription/Vehicule/Car_form.dart';
import 'package:rive_animation/screens/onboding/onboding_screen.dart';
import '../../screens/entryPoint/entry_point.dart';
import 'package:intl/intl.dart';
import '../../screens/onboding/components/sign_in_form.dart';

class SignUpClientForm extends StatefulWidget {
  const SignUpClientForm({Key? key}) : super(key: key);

  @override
  State<SignUpClientForm> createState() => _SignUpClientFormState();
}

class _SignUpClientFormState extends State<SignUpClientForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _identifiantController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _motdePasseController = TextEditingController();
  final TextEditingController _confirmerMotdePasseController = TextEditingController();
  final TextEditingController _typedecompteController = TextEditingController();
  final TextEditingController _photoprofilController = TextEditingController();
  final TextEditingController _datedeNaissanceController = TextEditingController();

  late SMITrigger check;
  late SMITrigger error;
  late SMITrigger reset;
  late SMITrigger confetti;

  @override
  void dispose() {
    _identifiantController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _mailController.dispose();
    _motdePasseController.dispose();
    _confirmerMotdePasseController.dispose();
    _typedecompteController.dispose();
    _photoprofilController.dispose();
    _datedeNaissanceController.dispose();
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

  void signUp(BuildContext context) async {
    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      setState(() {
        isShowLoading = true;
        isShowConfetti = true;
      });

      // Perform the upload
      await _uploadUserInfo();
    } else {
      // Form is not valid, do not proceed and hide animation
      setState(() {
        isShowLoading = false;
        isShowConfetti = false;
      });
    }
  }

  Future<void> _uploadUserInfo() async {
    final url = Uri.parse('http://192.168.137.1:8000/api/user'); // Update localhost with your local IP
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formattedDate = dateFormat.format(DateTime.now());
    final formData = {
      'identifiant': _identifiantController.text,
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'telephone': _telephoneController.text,
      'mail': null,
      'motdePasse': _motdePasseController.text,
      'typedecompte': "Client",
      'photoprofil': null,
      'latitude': null,
      'longitude': null,
      'datedeNaissance': _datedeNaissanceController.text,
      'statut': 'Actif',
      'dateCreation': formattedDate,
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
        print('User information uploaded successfully');
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
        title: Text('Informations client', style: TextStyle(color: Colors.white)),
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
                  // Identifiant
                  const Text("Nom d'utilisateur", style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _identifiantController,
                      decoration: InputDecoration(
                        hintText: "Ex: abdoul",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir l\'identifiant';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nom
                  const Text("Nom", style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        hintText: "Saisir le nom",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le nom';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Prénom
                  const Text("Prénom", style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _prenomController,
                      decoration: InputDecoration(
                        hintText: "Saisir le prénom",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le prénom';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Téléphone
                  const Text("Téléphone", style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _telephoneController,
                      decoration: InputDecoration(
                        hintText: "Ex: 99350888",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le téléphone';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mot de passe
                  const Text("Mot de passe", style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _motdePasseController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Saisir le mot de passe",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le mot de passe';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirmer Mot de passe
                  const Text("Confirmer Mot de passe", style: TextStyle(color: Colors.black54)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextFormField(
                      controller: _confirmerMotdePasseController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Confirmer le mot de passe",
                        fillColor: Colors.red.shade50,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez confirmer le mot de passe';
                        }
                        if (value != _motdePasseController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouton Soumettre
                  Center(
                    child: ElevatedButton(
                      onPressed: () => signUp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        'Continuer',
                        style: TextStyle(color: Colors.white, fontSize: 18),
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
                StateMachineController controller = getRiveController(artboard);
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
