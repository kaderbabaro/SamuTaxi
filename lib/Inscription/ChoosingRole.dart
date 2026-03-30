import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:rive_animation/Connexion/ConnexionPage.dart';
import 'Button/AnimatedChoosingBtnClient.dart';
import 'Button/animated_btnChoosingRole.dart';
import 'InscriptionChauffeur/Sing_updriver_form.dart';
import 'InscriptionClient/Sing_upClient_form.dart';

class ChoosingRole extends StatefulWidget {
  const ChoosingRole({super.key});

  @override
  State<ChoosingRole> createState() => _ChoosingRoleState();
}

class _ChoosingRoleState extends State<ChoosingRole> {
  late RiveAnimationController _btnAnimationController;
  late RiveAnimationController _BtnAnimationController;

  @override
  void initState() {
    _btnAnimationController = OneShotAnimation("active", autoplay: false);
    _BtnAnimationController = OneShotAnimation("active", autoplay: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset("assets/logo_samutaxi.png"),
                  ),
                ),
                const SizedBox(height: 20),

                // Titre principal
                const Text(
                  "Bienvenue sur SamuTaxi",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Veuillez choisir votre rôle pour continuer.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Boîte avec les options
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.drive_eta, color: Colors.red),
                          SizedBox(width: 10),
                          Text(
                            "Je suis un Chauffeur",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedChoosingRoleBtn(
                        btnAnimationController: _btnAnimationController,
                        press: () {
                          _btnAnimationController.isActive = true;
                          Future.delayed(const Duration(milliseconds: 800), () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration: const Duration(milliseconds: 600),
                                pageBuilder: (_, __, ___) => const SignUpPageDriver(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  final offsetAnimation = Tween<Offset>(
                                    begin: const Offset(1.0, 0.0), // Slide depuis la droite
                                    end: Offset.zero,
                                  ).animate(animation);

                                  final fadeAnimation = Tween<double>(
                                    begin: 0.0,
                                    end: 1.0,
                                  ).animate(animation);

                                  return SlideTransition(
                                    position: offsetAnimation,
                                    child: FadeTransition(
                                      opacity: fadeAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Je suis un Client",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedChoosingClientBtn(
                        btnAnimationController: _BtnAnimationController,
                        press: () {
                          _BtnAnimationController.isActive = true;
                          Future.delayed(const Duration(milliseconds: 800), () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration: const Duration(milliseconds: 600),
                                pageBuilder: (_, __, ___) => const SignUpPageClient(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  final offsetAnimation = Tween<Offset>(
                                    begin: const Offset(1.0, 0.0), // Slide depuis la droite
                                    end: Offset.zero,
                                  ).animate(animation);

                                  final fadeAnimation = Tween<double>(
                                    begin: 0.0,
                                    end: 1.0,
                                  ).animate(animation);

                                  return SlideTransition(
                                    position: offsetAnimation,
                                    child: FadeTransition(
                                      opacity: fadeAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const LoginPage()));
                            },
                            child: const Text("J'ai déja un compte",style: TextStyle(color: Colors.red),)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
