import 'package:delivery/data/profile_data.dart';
import 'package:delivery/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';
import 'success_page.dart';

class ConfirmPage extends StatefulWidget {
  const ConfirmPage({super.key, required this.scannedData});
  final ProfileData scannedData;

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  final _formKey = GlobalKey<FormState>();
  final _inputDecoration = const InputDecoration(
    filled: true,
    border: OutlineInputBorder(),
  );

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('verified', true);
    data.verified = true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          routes.removeLast();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'Confirm Identification Info',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                routes.removeLast();
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SingleChildScrollView(
                    child: Form(
                        key: _formKey,
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(
                              height: 40,
                            ),
                            SizedBox(
                                width: 300,
                                height: 81,
                                child: Row(children: [
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('First Name *'),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          width: 140,
                                          height: 48,
                                          child: TextFormField(
                                            initialValue:
                                                widget.scannedData.firstName,
                                            decoration: _inputDecoration,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your first name';
                                              }

                                              widget.scannedData.firstName =
                                                  value;
                                              return null;
                                            },
                                          ),
                                        ),
                                      ]),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Last Name *'),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                            width: 140,
                                            height: 48,
                                            child: TextFormField(
                                              initialValue:
                                                  widget.scannedData.lastName,
                                              decoration: _inputDecoration,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please enter your last name';
                                                }

                                                widget.scannedData.lastName =
                                                    value;
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
                                  const Text('Nationality *'),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                      width: 300,
                                      height: 48,
                                      child: TextFormField(
                                        initialValue:
                                            widget.scannedData.nationality,
                                        decoration: _inputDecoration,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          widget.scannedData.nationality =
                                              value;
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
                                  const Text('Identification Number *'),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                      width: 300,
                                      height: 48,
                                      child: TextFormField(
                                        initialValue:
                                            widget.scannedData.idNumber,
                                        decoration: _inputDecoration,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          widget.scannedData.idNumber = value;
                                          return null;
                                        },
                                      )),
                                ]),
                            const SizedBox(
                              height: 67,
                            ),
                            SizedBox(
                              width: 220,
                              height: 52,
                              child: MaterialButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    if (widget.scannedData.firstName!
                                                .toLowerCase() ==
                                            data.firstName!.toLowerCase() &&
                                        widget.scannedData.lastName!
                                                .toLowerCase() ==
                                            data.lastName!.toLowerCase()) {
                                      saveData();
                                      MaterialPageRoute route =
                                          MaterialPageRoute(
                                        builder: (context) =>
                                            const SuccessPage(),
                                      );
                                      routes.add(route);
                                      Navigator.push(
                                        context,
                                        route,
                                      );
                                    } else {
                                      showAlert(context, 'Error',
                                          'Your personal information does not match the scanned document. Please try again.');
                                    }
                                  } else {
                                    print('Form is not valid');
                                  }
                                },
                                color: Colors.black,
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ))),
              ]),
        ));
  }
}
