import 'package:delivery/global.dart';
import 'package:flutter/material.dart';

import 'signup_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          routes.removeLast();
          return true;
        },
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                    width: 200,
                    height: 280,
                    child: Image.asset(
                      'images/icon-man.png',
                      fit: BoxFit.contain,
                    )),
                const SizedBox(
                  height: 47,
                ),
                const SizedBox(
                  width: 269,
                  height: 60,
                  child: Text(
                    'Last Mile Delivery',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 47,
                ),
                SizedBox(
                  width: 220,
                  height: 52,
                  child: MaterialButton(
                    onPressed: () {
                      MaterialPageRoute route = MaterialPageRoute(
                          builder: (context) => const SignUpPage());
                      routes.add(route);
                      Navigator.push(
                        context,
                        route,
                      );
                    },
                    color: Colors.black,
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
