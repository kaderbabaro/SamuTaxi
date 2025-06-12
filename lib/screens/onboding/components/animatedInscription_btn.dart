import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart';

class AnimatedInsBtn extends StatelessWidget {
  const AnimatedInsBtn({
    super.key,
    required RiveAnimationController BtnAnimationController,
    required this.press,
  }) : _BtnAnimationController = BtnAnimationController;

  final RiveAnimationController _BtnAnimationController;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: SizedBox(
        height: 64,
        width: 260,
        child: Stack(children: [
          RiveAnimation.asset(
            "assets/RiveAssets/button.riv",
            controllers: [_BtnAnimationController],
          ),
          const Positioned.fill(
              top: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_right),
                  SizedBox(
                    width: 8,
                  ),
                  Text("M'inscrire",
                      style: TextStyle(fontWeight: FontWeight.w600))
                ],

              )),
        ]),
      ),
    );
  }
}
