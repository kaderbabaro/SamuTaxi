import 'package:flutter/material.dart';
import '../../../model/menu.dart';
import '../../../utils/rive_utils.dart';
import '../info_card.dart';
import '../side_menu.dart';
import '../../../onboding/components/sign_in_form.dart';
import '../../../../services/Apiservices/User.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;



class SideBarDriver extends StatefulWidget {
  const SideBarDriver({super.key});

  @override
  State<SideBarDriver> createState() => _SideBarState();
}

const String baseUrl = 'http://192.168137.1:8000/api/users';


class _SideBarState extends State<SideBarDriver> {
  Menu selectedSideMenu = sidebarMenus.first;

  @override
  Widget build(BuildContext context) {

    final Map<String, String> args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final String username = args['username']!;
    final String typedecompte = args['typecompte']!;

    return SafeArea(
      child: Container(
        width: 150,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFB20909),
          borderRadius: BorderRadius.all(
            Radius.circular(30),
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoCard(
                name: username,
                bio: typedecompte, // Display password or any other information
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 5, bottom: 0),
                child: Text(
                  "Général".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenudispo
                  .map((menu) => SideMenu(
                menu: menu,
                selectedMenu: selectedSideMenu,
                press: () {
                  if (menu.rive != null) {
                    RiveUtils.changeSMIBoolState(menu.rive!.status!);
                  }
                  setState(() {
                    selectedSideMenu = menu;
                  });
                },
                riveOnInit: (artboard) {
                  if (menu.rive != null) {
                    menu.rive!.status = RiveUtils.getRiveInput(artboard,
                        stateMachineName: menu.rive!.stateMachineName);
                  }
                },
              ))
                  .toList(),
              ...sidebarMenus
                  .map((menu) => SideMenu(
                menu: menu,
                selectedMenu: selectedSideMenu,
                press: () {
                  if (menu.rive != null) {
                    RiveUtils.changeSMIBoolState(menu.rive!.status!);
                  }
                  setState(() {
                    selectedSideMenu = menu;
                  });
                },
                riveOnInit: (artboard) {
                  if (menu.rive != null) {
                    menu.rive!.status = RiveUtils.getRiveInput(artboard,
                        stateMachineName: menu.rive!.stateMachineName);
                  }
                },
              ))
                  .toList(),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 10, bottom: 0),
                child: Text(
                  "Accessibilités".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenus2
                  .map((menu) => SideMenu(
                menu: menu,
                selectedMenu: selectedSideMenu,
                press: () {
                  if (menu.rive != null) {
                    RiveUtils.changeSMIBoolState(menu.rive!.status!);
                  }
                  setState(() {
                    selectedSideMenu = menu;
                  });
                },
                riveOnInit: (artboard) {
                  if (menu.rive != null) {
                    menu.rive!.status = RiveUtils.getRiveInput(artboard,
                        stateMachineName: menu.rive!.stateMachineName);
                  }
                },
              ))
                  .toList(),
              const SizedBox(
                height: 25,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 60, bottom: 10),
                child: Text(
                  "Déconnexion".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarBottomMenus
                  .map((menu) => SideMenu(
                menu: menu,
                selectedMenu: selectedSideMenu,
                press: () {
                  if (menu.rive != null) {
                    RiveUtils.changeSMIBoolState(menu.rive!.status!);
                  }
                  setState(() {
                    selectedSideMenu = menu;
                  });
                },
                riveOnInit: (artboard) {
                  if (menu.rive != null) {
                    menu.rive!.status = RiveUtils.getRiveInput(artboard,
                        stateMachineName: menu.rive!.stateMachineName);
                  }
                },
              ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}
