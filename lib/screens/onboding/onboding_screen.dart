import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:rive_animation/Inscription/ChoosingRole.dart';
import 'package:rive_animation/screens/onboding/components/animated_btn.dart';

import '../../Inscription/InscriptionClient/Sing_upClient_form.dart';
import '../../Inscription/InscriptionClient/Sing_up_client.dart';
import 'components//custom_sign_in.dart';
import 'components/animatedInscription_btn.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isSignInDialogShown = false;
  late RiveAnimationController _btnAnimationController;
  late RiveAnimationController _btnAnimationController2;

  @override
  void initState() {
    _btnAnimationController = OneShotAnimation("active", autoplay: false);
    _btnAnimationController2 = OneShotAnimation("active",autoplay: false);
    super.initState();
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
            child: Image.asset('assets/Backgrounds/Spline.png')),
        Positioned.fill(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
        )),
        const RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
        Positioned.fill(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
          child: const SizedBox(),
        )),
        AnimatedPositioned(
          duration: Duration(milliseconds: 240),
          top: isSignInDialogShown ? -50 : 0,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacer(),
                    const SizedBox(
                      width: 260,
                      child: Column(children: [
                        Text(
                          "Trouve un taxi en ligne",
                          style: TextStyle(
                              fontSize: 60, fontFamily: "Poppins", height: 1.2),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Text(
                            "Samutaxi, commande un taxi en ligne dans la ville de Niamey. Profitez d'un service fiable pour toute vos course.\n\nVeullez vous connectez si vous êtes inscrit.")
                      ]),
                    ),
                    const Spacer(
                      flex: 2,
                    ),
                    AnimatedBtn(
                      btnAnimationController: _btnAnimationController,
                      press: () {
                        _btnAnimationController.isActive = true;
                        Future.delayed(Duration(milliseconds: 800), () {
                          setState(() {
                            isSignInDialogShown = true;
                          });
                          customSigninDialog(context, onClosed: (_) {
                            setState(() {
                              isSignInDialogShown = false;
                            });
                          });
                        });
                      },
                    ),
                    AnimatedInsBtn(
                      BtnAnimationController: _btnAnimationController2,
                      press: () {
                        _btnAnimationController2.isActive = true;
                        Future.delayed(Duration(milliseconds: 800), () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context)=> ChoosingRole()
                              ));
                        });
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        "+250 vidéos d'apprentissage d'usage, Bénéficiez d'un coupon de reduction pour toute vos courses en accomplissant +75 defis avec SamuTaxi",
                        style: TextStyle(),
                      ),
                    )
                  ]),
            ),
          ),
        )
      ],
    ));
  }
}
