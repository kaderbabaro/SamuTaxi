import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../screens/onboding/onboding_screen.dart';
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
  bool isSignInDialogShown = false;
  bool isSignInDialogShown2 = false;
  late RiveAnimationController _btnAnimationController;
  late RiveAnimationController _BtnAnimationController;

  @override
  void initState() {
    _btnAnimationController = OneShotAnimation("active", autoplay: false);
    _BtnAnimationController = OneShotAnimation("active", autoplay: false);
    super.initState();
  }

  _showAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.cyan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            bottom: 200,
            left: 100,
            child: Image.asset('assets/Backgrounds/Spline.png'),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
            ),
          ),
          const RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: const SizedBox(),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 240),
            top: isSignInDialogShown ? -50 : 0,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: Column(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          "S'inscrire",
                          style: TextStyle(
                              fontSize: 30, fontFamily: "Poppins", height: 1.2),
                        ),
                        Text(
                          "Incrivez sur l'application.",
                        ),
                        SizedBox(
                          height: 45,
                        ),
                        Container(
                          height: 180,
                          width: 180,
                          child: Image.asset("assets/Gif/OrderNow.gif"),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Row(
                          children: [
                            Icon(Icons.drive_eta),
                            Text(
                              "Chauffeur",
                              style: TextStyle(
                                  fontSize: 25, fontFamily: "Poppins", height: 1.2),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    AnimatedChoosingRoleBtn(
                      btnAnimationController: _btnAnimationController,
                      press: () {
                        _btnAnimationController.isActive = true;
                        Future.delayed(Duration(milliseconds: 800), () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpDriverForm()));
                        });

                      },
                    ),
                    SizedBox(
                      height: 15,
                   ),
                    Row(
                      children: [
                        Icon(Icons.supervised_user_circle_outlined),
                        Text(
                          "Client",
                          style: TextStyle(
                              fontSize: 25, fontFamily: "Poppins", height: 1.2),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    AnimatedChoosingClientBtn(
                      btnAnimationController: _BtnAnimationController,
                      press: () {
                        _BtnAnimationController.isActive = true;
                        Future.delayed(Duration(milliseconds: 800), () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpClientForm()));
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 580,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingScreen(),
                    ),
                  );
                },
                child: Text("J'ai deja un compte"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
