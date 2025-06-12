import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rive_animation/Inscription/ChoosingRole.dart';
import 'package:rive_animation/Inscription/InscriptionChauffeur/Sing_up_driver.dart';
import 'package:rive_animation/Inscription/InscriptionClient/Sing_upClient_form.dart';
import 'package:rive_animation/Inscription/Vehicule/Car_form.dart';
import 'package:rive_animation/screens/Vues/Abonnement_list.dart';
import 'package:rive_animation/screens/Vues/Aide.dart';
import 'package:rive_animation/screens/Vues/CommandeTaxi.dart';
import 'package:rive_animation/screens/Vues/CoursePage.dart';
import 'package:rive_animation/screens/Vues/HistoriqueCourse.dart';
import 'package:rive_animation/screens/Vues/MapDriver.dart';
import 'package:rive_animation/screens/Vues/PrendreClient.dart';
import 'package:rive_animation/screens/Vues/PrincipalMaps.dart';
import 'package:rive_animation/screens/Vues/Tarif_list.dart';
import 'package:rive_animation/screens/Vues/UserLocation.dart';
import 'package:rive_animation/screens/entryPoint/Entrypoint_Driver.dart';
import 'package:rive_animation/screens/entryPoint/entry_point.dart';
import 'package:rive_animation/screens/home/home_screen.dart';

import 'package:rive_animation/screens/onboding/onboding_screen.dart';

import 'Inscription/InscriptionChauffeur/Sing_updriver_form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SamuTaxi',
      initialRoute: '/Onboding',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFEEF1F8),
        primarySwatch: Colors.blue,
        fontFamily: "Inter",

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(height: 0),
          border: defaultInputBorder,
          enabledBorder: defaultInputBorder,
          focusedBorder: defaultInputBorder,
          errorBorder: defaultInputBorder,
        ),
      ),

        routes: {
        '/Onboding' : (context) =>  OnboardingScreen(),
        '/home' : (context) => EntryPoint(),
          '/tarif' : (context) => TarifsList(),
          '/abonnement': (coontext) => AbonnementListPage(),
          '/Aide': (coontext) => AidePage(),
          '/historique' : (context) => CourseList(),
          '/course' : (context) => MapView(),
          '/commander': (context) => OrderTaxiPage(),
          '/MapDriver' : (context) => EntryPointDriver(),
          '/coursepage' : (context) => CoursePage(),
          '/carcreate' : (context) => CarForm(),
          '/clientdestination' : (context) => Prendreclient(),
        }

      //home: SignUpDriverForm(),
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);
