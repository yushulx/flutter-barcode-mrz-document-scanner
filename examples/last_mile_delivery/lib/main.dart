import 'package:delivery/data/profile_data.dart';
import 'package:delivery/order_page.dart';
import 'package:delivery/profile_page.dart';
import 'package:delivery/global.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<SharedPreferences> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await initBarcodeSDK();
    await initMRZSDK();
    await initDocumentSDK();
    return prefs;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last Mile Delivery',
      home: FutureBuilder<SharedPreferences>(
        future: loadData(),
        builder:
            (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator(); // Loading indicator
          }
          final String email = snapshot.data!.getString('email') ?? '';
          final bool verified = snapshot.data!.getBool('verified') ?? false;
          Future.microtask(() {
            MaterialPageRoute route;
            data = ProfileData(
                email: email,
                firstName: snapshot.data!.getString('firstName') ?? '',
                lastName: snapshot.data!.getString('lastName') ?? '',
                password: snapshot.data!.getString('password') ?? '',
                verified: snapshot.data!.getBool('verified') ?? false);
            if (verified) {
              route =
                  MaterialPageRoute(builder: (context) => const OrderPage());
            } else {
              if (email.isEmpty) {
                route =
                    MaterialPageRoute(builder: (context) => const MyHomePage());
              } else {
                route = MaterialPageRoute(
                    builder: (context) => const ProfilePage());
              }
            }
            routes.add(route);
            Navigator.pushReplacement(context, route);
          });
          return Container();
        },
      ),
    );
  }
}
