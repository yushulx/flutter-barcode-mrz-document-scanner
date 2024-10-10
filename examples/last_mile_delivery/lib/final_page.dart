import 'package:delivery/order_page.dart';
import 'package:delivery/global.dart';
import 'package:flutter/material.dart';

class FinalPage extends StatefulWidget {
  const FinalPage({super.key});

  @override
  State<FinalPage> createState() => _FinalPageState();
}

class _FinalPageState extends State<FinalPage> {
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
                      'images/icon-confirmed.png',
                      fit: BoxFit.contain,
                    )),
                const SizedBox(
                  width: 298,
                  height: 45,
                  child: Text(
                    'Delivery Confirmed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const SizedBox(
                  width: 284,
                  height: 48,
                  child: Text(
                    'You have successfully confirmed the delivery. Thank you!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 47,
                ),
                SizedBox(
                  width: 280,
                  height: 52,
                  child: MaterialButton(
                    onPressed: () {
                      MaterialPageRoute route = MaterialPageRoute(
                        builder: (context) => const OrderPage(),
                      );

                      routes.add(route);
                      Navigator.push(
                        context,
                        route,
                      );

                      while (routes.length != 1) {
                        try {
                          Navigator.removeRoute(context, routes[0]);
                          routes.removeAt(0);
                        } catch (e) {
                          print(e);
                        }
                      }
                    },
                    color: Colors.black,
                    child: const Text(
                      'Back to Assignment List',
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
