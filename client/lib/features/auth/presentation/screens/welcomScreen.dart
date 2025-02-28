import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:first_app/theme/theme.dart';
import 'package:first_app/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:first_app/features/auth/presentation/widgets/welcome_button.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 40,
              ),
              child: Center(
                child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                            text: 'Welcome Back!\n',
                            style: TextStyle(
                              fontSize: 45.0,
                              fontWeight: FontWeight.w600,
                            )),
                        TextSpan(
                            text:
                                '\nEnter personal details to your employee account',
                            style: TextStyle(
                              fontSize: 20,
                              // height: 0,
                            ))
                      ],
                    ),
              ),
          ))),

          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'SIGN IN',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (e) => const SignInScreen(),
                          ),
                        );
                      },
                      color: Colors.transparent,
                      textColor: Colors.white,
                  ),
                  ),
              
                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'SIGN UP',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (e) => const SignUpScreen(),
                          ),
                        );
                      },
                      color: Colors.white,
                      textColor: lightColorScheme.primary,
                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
