import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'Car_form.dart';

class CarInscription extends StatefulWidget {
  const CarInscription({super.key});

  @override
  State<CarInscription> createState() => _CarState();
}

class _CarState extends State<CarInscription> {
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
    )
    )
            ]),
    );
  }
}
