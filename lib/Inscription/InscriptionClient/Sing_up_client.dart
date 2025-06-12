import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'Sing_upClient_form.dart';

class SingUpClient extends StatefulWidget {
  const SingUpClient({super.key});

  @override
  State<SingUpClient> createState() => _SingUpClientState();
}

class _SingUpClientState extends State<SingUpClient> {
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
