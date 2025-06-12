import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../model/menu.dart';

class SideMenu extends StatelessWidget {
  const SideMenu(
      {super.key,
        required this.menu,
        required this.press,
        required this.riveOnInit,
        required this.selectedMenu});

  final Menu menu;
  final VoidCallback press;
  final ValueChanged<Artboard> riveOnInit;
  final Menu selectedMenu;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24),
          child: Divider(color: Colors.white24, height: 1),
        ),
        Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              width: selectedMenu == menu ? 288 : 0,
              height: 56,
              left: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFA0A2A4),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, menu.route);
              },
              leading: SizedBox(
                height: 36,
                width: 36,
                child: menu.rive != null ? RiveAnimation.asset(
                  menu.rive!.src,
                  artboard: menu.rive!.artboard,
                  onInit: riveOnInit,
                ) : Icon(
                  menu.icon,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              title: Text(
                menu.title,
                style: const TextStyle(color: Colors.white),

              ),
            ),
          ],
        ),
      ],
    );
  }
}
