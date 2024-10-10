import 'package:delivery/login_page.dart';
import 'package:delivery/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _inputDecoration = const InputDecoration(
    filled: true,
    border: OutlineInputBorder(),
  );

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', data.firstName ?? '');
    await prefs.setString('lastName', data.lastName ?? '');
    await prefs.setString('email', data.email ?? '');
    await prefs.setString('password', data.password ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          routes.removeLast();
          return true;
        },
        child: Scaffold(
            body: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 79,
                  ),
                  const SizedBox(
                    width: 252,
                    height: 90,
                    child: Text(
                      'Register as a Delivery Driver',
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
                  SizedBox(
                      width: 300,
                      height: 81,
                      child: Row(children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('First Name *'),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                width: 140,
                                height: 48,
                                child: TextFormField(
                                  decoration: _inputDecoration,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your first name';
                                    }
                                    data.firstName = value;
                                    return null;
                                  },
                                ),
                              ),
                            ]),
                        const SizedBox(
                          width: 20,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Last Name *'),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                  width: 140,
                                  height: 48,
                                  child: TextFormField(
                                    decoration: _inputDecoration,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your last name';
                                      }
                                      data.lastName = value;
                                      return null;
                                    },
                                  )),
                            ]),
                      ])),
                  const SizedBox(
                    height: 10,
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email *'),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                            width: 300,
                            height: 48,
                            child: TextFormField(
                              decoration: _inputDecoration,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                data.email = value;
                                // Add more complex validation here if needed
                                return null;
                              },
                            )),
                      ]),
                  const SizedBox(
                    height: 10,
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Password *'),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                            width: 300,
                            height: 48,
                            child: TextFormField(
                              decoration: _inputDecoration,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                data.password = value;
                                // Add more complex validation here if needed
                                return null;
                              },
                            )),
                      ]),
                  const SizedBox(
                    height: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Confirm Password *'),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                          width: 300,
                          height: 48,
                          child: TextFormField(
                            decoration: _inputDecoration,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != data.password) {
                                return 'Passwords do not match';
                              }

                              return null;
                            },
                          )),
                    ],
                  ),
                  const SizedBox(
                    height: 47,
                  ),
                  SizedBox(
                    width: 220,
                    height: 52,
                    child: MaterialButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          saveData();
                          MaterialPageRoute route = MaterialPageRoute(
                              builder: (context) => const ProfilePage());
                          routes.add(route);
                          Navigator.push(
                            context,
                            route,
                          );
                        } else {
                          print('Form is not valid');
                        }
                      },
                      color: Colors.black,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      InkWell(
                        onTap: () {
                          MaterialPageRoute route = MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          );
                          routes.add(route);
                          Navigator.push(
                            context,
                            route,
                          );
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Color(0xffFE8E14),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              )),
        )));
  }
}
