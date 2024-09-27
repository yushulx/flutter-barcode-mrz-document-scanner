import 'package:flutter/material.dart';
import 'tab_page.dart';
import 'dart:async';
import 'global.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<int> loadData() async {
    _fetchData();
    return await initBarcodeSDK();
  }

  void _fetchData() async {
    List<dynamic> list = [
      {
        "LotNumber": "000123457118",
        "MedicationName": "Medicorin",
        "ManufactureDate": "2023-01-09T16:00:00.000Z",
        "ExpirationDate": "2025-01-09T16:00:00.000Z",
        "BatchSize": 5000,
        "QualityCheckStatus": "Passed"
      },
      {
        "LotNumber": "000123457286",
        "MedicationName": "Panadol Extra",
        "ManufactureDate": "2023-02-14T16:00:00.000Z",
        "ExpirationDate": "2025-02-14T16:00:00.000Z",
        "BatchSize": 8000,
        "QualityCheckStatus": "Passed"
      },
      {
        "LotNumber": "000123457231",
        "MedicationName": "AspiraClear",
        "ManufactureDate": "2023-03-19T16:00:00.000Z",
        "ExpirationDate": "2025-03-19T16:00:00.000Z",
        "BatchSize": 6000,
        "QualityCheckStatus": "Passed"
      },
      {
        "LotNumber": "000123457149",
        "MedicationName": "Zyncetamol",
        "ManufactureDate": "2023-04-24T16:00:00.000Z",
        "ExpirationDate": "2025-04-24T16:00:00.000Z",
        "BatchSize": 4500,
        "QualityCheckStatus": "Passed"
      },
      {
        "LotNumber": "000123457002",
        "MedicationName": "Fluconozap",
        "ManufactureDate": "2023-05-29T16:00:00.000Z",
        "ExpirationDate": "2025-05-29T16:00:00.000Z",
        "BatchSize": 5000,
        "QualityCheckStatus": "Failed"
      },
      {
        "LotNumber": "000123456968",
        "MedicationName": "Antibiotix",
        "ManufactureDate": "2023-06-04T16:00:00.000Z",
        "ExpirationDate": "2025-06-04T16:00:00.000Z",
        "BatchSize": 7000,
        "QualityCheckStatus": "Passed"
      },
      {
        "LotNumber": "000123457040",
        "MedicationName": "Feverend",
        "ManufactureDate": "2023-07-10T16:00:00.000Z",
        "ExpirationDate": "2025-07-10T16:00:00.000Z",
        "BatchSize": 5500,
        "QualityCheckStatus": "Passed"
      },
      {
        "LotNumber": "000123456920",
        "MedicationName": "ColdAway",
        "ManufactureDate": "2023-08-15T16:00:00.000Z",
        "ExpirationDate": "2025-08-15T16:00:00.000Z",
        "BatchSize": 6000,
        "QualityCheckStatus": "Passed"
      },
      {
        "LotNumber": "000123457071",
        "MedicationName": "Allergease",
        "ManufactureDate": "2023-09-20T16:00:00.000Z",
        "ExpirationDate": "2025-09-20T16:00:00.000Z",
        "BatchSize": 4800,
        "QualityCheckStatus": "Passed"
      },
      {
        "LotNumber": "000123457156",
        "MedicationName": "CoughNoMore",
        "ManufactureDate": "2023-10-25T16:00:00.000Z",
        "ExpirationDate": "2025-10-25T16:00:00.000Z",
        "BatchSize": 5200,
        "QualityCheckStatus": "Passed"
      }
    ];

    database = {
      for (var item in list) item['LotNumber'] as String: Pharma.fromJson(item)
    };

    // final response = await http.get(Uri.parse(
    //     'https://script.google.com/macros/s/AKfycbyPEx3THAbcLTNaJNOkQ1O3puTmQKXXOE_gkOGyKMzfIEUTr484qS8Dsi7-kTKpD333/exec'));

    // if (response.statusCode == 200) {
    //   List<dynamic> list = json.decode(response.body);
    //   database = {
    //     for (var item in list)
    //       item['LotNumber'] as String: Pharma.fromJson(item)
    //   };
    // } else {
    //   throw Exception('Failed to load data');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamsoft Barcode Detection',
      theme: ThemeData(
        scaffoldBackgroundColor: colorMainTheme,
      ),
      home: FutureBuilder<int>(
        future: loadData(),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator(); // Loading indicator
          }
          Future.microtask(() {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const TabPage()));
          });
          return Container();
        },
      ),
    );
  }
}
