import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'reader_screen.dart';
import 'scan_provider.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.title});

  final String title;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    ScanProvider scanProvider = Provider.of<ScanProvider>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                var result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
                scanProvider.types = result['format'];
              },
            ),
          ],
        ),
        body: Center(
          child: GridView.count(
            crossAxisCount: 2, // set the number of columns to 2
            mainAxisSpacing: 16, // set the spacing between each row
            crossAxisSpacing: 16, // set the spacing between each column
            padding: const EdgeInsets.all(16), // set the padding
            children: [
              Container(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ScannerScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.square(
                        64), // Set the size of the button to be square
                  ),
                  child: Stack(
                    children: const [
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Inventory Scan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.camera,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReaderScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.square(
                        64), // Set the size of the button to be square
                  ),
                  child: Stack(
                    children: const [
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Image File Scan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.image,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Add the code for the rest of the buttons
            ],
          ),
        ));
  }
}
