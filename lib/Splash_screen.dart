import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rive_animation/screens/HomeChauffeur/ChauffeurHomePage.dart';
import 'package:rive_animation/screens/HomeV2/HomeV2.dart';
import '../../local_storage_services.dart';
import 'Inscription/ChoosingRole.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkIfFileExists();
    _decideRoute();
  }

  void checkIfFileExists() async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/user_data.json';
    final file = File(filePath);

    print('Chemin complet : $filePath');
    print('Existe ? ${await file.exists()}');

    if (await file.exists()) {
      print('Contenu : ${await file.readAsString()}');
    }
  }

  Future<void> _decideRoute() async {
    final user = await LocalStorageService.getUser();
    await Future.delayed(const Duration(milliseconds: 800)); // optionnel

    if (!mounted) return;

    if (user == null || user['id'] == null) {
      _go(const ChoosingRole());
      return;
    }

    final typeRaw = (user['type_user'] ?? '').toString().toLowerCase().trim();

    switch (typeRaw) {
      case 'chauffeur':
        _go(ChauffeurHomePage(userId: user['id']));
        break;

      case 'client':
        _go(HomeV2(userId: user['id'],
          username: user['nom_utilisateur'],
          telephone: user['numero_telephone'],));
        break;

      default:
      // Type inconnu → rebasculer sur inscription ou écran de choix de rôle
        _go(const ChoosingRole());
        break;
    }
  }

  void _go(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 500),
        // durée de la transition
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(flex: 3),
            Center(
              child: Image.asset(
                "assets/logo_samutaxi.png",
                width: 52, // ajuste la taille si nécessaire
                height: 52,
              ),
            ),
            const Spacer(flex: 3),
            const Padding(
              padding: EdgeInsets.only(bottom: 65.0),
              child: CircularProgressIndicator(
                color: Colors.red, // ou la couleur de ton thème
              ),
            ),
          ],
        ),
      ),
    );
  }
}
