import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rive/rive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignInForm extends StatefulWidget {
  const SignInForm({
    Key? key,
  }) : super(key: key);

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isShowLoading = false;
  bool isShowConfetti = false;

  late SMITrigger check;
  late SMITrigger error;
  late SMITrigger reset;
  late SMITrigger confetti;

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  StateMachineController getRiveController(Artboard artboard) {
    StateMachineController? controller =
    StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    return controller;
  }


  void signIn(BuildContext context) async {
    setState(() {
      isShowLoading = true;
      isShowConfetti = true;
    });

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String type = "";

    try {
      // Construct the API login URL
      Uri url = Uri.parse('http://192.168.137.1:8000/api/userslog/$username');

      final String baseUrl = 'http://192.168.137.1:8000/api/users';

      // Send the HTTP POST request with username and password
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'password': password}),
      );
      // Check the HTTP response status
      if (response.statusCode == 200) {
       // Parse the response
        final user = json.decode(response.body);
        final String type = user['typedecompte'];
        final int id = user['id'];

        check.fire();
        await Future.delayed(Duration(seconds: 2));
        confetti.fire();

        if (type == 'Chauffeur') {
          Navigator.pushReplacementNamed(
            context,
            '/MapDriver',
            arguments: {'username': username, 'typecompte': type},
          );
        } else if (type == 'Client') {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'username': username, 'typecompte': type},
          );
        } else {
          // Handle unknown account type
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Type de compte inconnu.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }  else if (response.statusCode == 401) {
        // Incorrect password
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nom d\'utilisateur ou mot de passe incorrect.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          isShowLoading = false;
        });
      } else if (response.statusCode == 404) {
        // User not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur non trouvé.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          isShowLoading = false;
        });
      } else {
        // Other HTTP errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la connexion. Veuillez réessayer plus tard.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          isShowLoading = false;
        });
      }
    } catch (e) {
      // Handle any exceptions
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue. Veuillez réessayer plus tard.'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        isShowLoading = false;
      });
    } finally {
      // Reset loading and confetti states
      setState(() {
        isShowLoading = false;
        isShowConfetti = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nom d'utilisateur",
                style: TextStyle(color: Colors.black54),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                child: TextFormField(
                  controller: _usernameController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Saisissez le nom d'utilisateur";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SvgPicture.asset("assets/icons/User.svg"),
                    ),
                  ),
                ),
              ),
              const Text(
                "Mot de passe",
                style: TextStyle(color: Colors.black54),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                child: TextFormField(
                  controller: _passwordController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Votre mot de passe s'il vous plait";
                    }
                    return null;
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SvgPicture.asset("assets/icons/password.svg"),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    signIn(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF77D8E),
                    minimumSize: const Size(double.infinity, 56),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.arrow_right,
                    color: Color(0xFFFE0037),
                  ),
                  label: const Text("Se connecter"),
                ),
              ),
            ],
          ),
        ),
        isShowLoading
            ? CustomPositioned(
          child: RiveAnimation.asset(
            "assets/RiveAssets/check.riv",
            onInit: (artboard) {
              StateMachineController controller =
              getRiveController(artboard);
              check = controller.findSMI("Check") as SMITrigger;
              error = controller.findSMI("Error") as SMITrigger;
              reset = controller.findSMI("Reset") as SMITrigger;
            },
          ),
        )
            : const SizedBox(),
        isShowConfetti
            ? CustomPositioned(
          child: Transform.scale(
            scale: 6,
            child: RiveAnimation.asset(
              "assets/RiveAssets/confetti.riv",
              onInit: (artboard) {
                StateMachineController controller =
                getRiveController(artboard);
                confetti =
                controller.findSMI("Trigger explosion") as SMITrigger;
              },
            ),
          ),
        )
            : const SizedBox(),
      ],
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({
    Key? key,
    required this.child,
    this.size = 100,
  }) : super(key: key);

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          Spacer(),
          SizedBox(
            height: size,
            width: size,
            child: child,
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}
