import 'package:flutter/material.dart';
import 'rive_model.dart';

class Menu {
  final String title;
  final RiveModel? rive;
  final IconData? icon;
  final String route;
  final Function(BuildContext)? action;

  Menu({required this.title, this.rive, this.icon, required this.route, this.action});
}

final List<Menu> sidebarMenuscourse = [
  Menu(
    title: "Courses",
    route: "/course",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "SEARCH",
        stateMachineName: "SEARCH_Interactivity"),
  ),
];

final List<Menu> sidebarMenudispo = [
  Menu(
    title: "Courses disponibles",
    route: '/historique',
    icon: Icons.map,
  ),
];

final List<Menu> sidebarMenus = [
  Menu(
    title: "Abonnements",
    route: '/abonnement',
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "LIKE/STAR",
        stateMachineName: "STAR_Interactivity"),
  ),
  Menu(
    title: "Comptes de paiements",
    route: '/comptepaiement',
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "USER",
        stateMachineName: "USER_Interactivity"),
  ),
  Menu(
    title: "Tarifs",
    route: '/tarif',
    icon: Icons.attach_money,
  ),
];

final List<Menu> sidebarMenus2 = [
  Menu(
    title: "Aide",
    route: '/Aide',
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "CHAT",
        stateMachineName: "CHAT_Interactivity"),
  ),
];

final List<Menu> sidebarBottomMenus = [
  Menu(
    title: "Se déconnecter",
    route: '',
    icon: Icons.logout,
    action: (context) => Navigator.pop(context),
  ),
];

final List<Menu> bottomNavItems = [
  Menu(
    title: "Aide",
    route: '/Aide',
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "CHAT",
        stateMachineName: "CHAT_Interactivity"),
  ),
  Menu(
    title: "Courses",
    route: "/course",
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "SEARCH",
        stateMachineName: "SEARCH_Interactivity"),
  ),
  Menu(
    title: "Tarifs",
    route: '/tarif',
    icon: Icons.attach_money,
  ),
  Menu(
    title: "Abonnements",
    route: '/abonnement',
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "LIKE/STAR",
        stateMachineName: "STAR_Interactivity"),
  ),
  Menu(
    title: "Compte de paiements",
    route: '/comptepaiement',
    rive: RiveModel(
        src: "assets/RiveAssets/icons.riv",
        artboard: "USER",
        stateMachineName: "USER_Interactivity"),
  ),
];
