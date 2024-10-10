import 'package:delivery/doc_scan_page.dart';
import 'package:delivery/final_page.dart';
import 'package:flutter/material.dart';

import 'data/order_data.dart';
import 'global.dart';

import 'dart:ui' as ui;

class ImagePainter extends CustomPainter {
  ImagePainter(this.image);
  ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    if (image != null) {
      canvas.drawImage(image!, Offset.zero, paint);
    }
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) => true;
}

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key, required this.order});

  final OrderData order;

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  ui.Image? normalizedUiImage;

  Widget createCustomImage(BuildContext context, ui.Image image) {
    return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
            width: image.width.toDouble(),
            height: image.height.toDouble(),
            child: CustomPaint(
              painter: ImagePainter(image),
            )));
  }

  List<Widget> getDocImage() {
    if (normalizedUiImage == null) {
      return <Widget>[
        const SizedBox(
          height: 216,
        ),
        SizedBox(
          width: 240,
          height: 52,
          child: MaterialButton(
            color: Colors.black,
            onPressed: () async {
              MaterialPageRoute route = MaterialPageRoute(
                builder: (context) => const DocScanPage(),
              );
              routes.add(route);
              var result = await Navigator.push(
                context,
                route,
              );

              if (result != null) {
                setState(() {
                  normalizedUiImage = result;
                });
              }
            },
            child: const Text(
              'Scan Delivery Document',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        )
      ];
    } else {
      return <Widget>[
        const SizedBox(
          height: 16,
        ),
        Expanded(
            child: SingleChildScrollView(
          child: createCustomImage(context, normalizedUiImage!),
        ))
        // SizedBox(
        //   height: 116,
        //   child: createCustomImage(context, normalizedUiImage!),
        // ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
        onWillPop: () async {
          routes.removeLast();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'Proof of Delivery',
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
          body: Column(
            children: [
              Container(
                width: screenWidth,
                height: 149,
                decoration: const BoxDecoration(
                  color: Color(0xffF5F5F5),
                ),
                child: Column(
                  children: <Widget>[
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        Text(
                          'Order ID:${widget.order.id}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: screenWidth - 278,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Image.asset(
                          "images/icon-address.png",
                          width: 25,
                          height: 25,
                        ),
                        Text(
                          '${widget.order.address}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Image.asset(
                          "images/icon-time.png",
                          width: 25,
                          height: 25,
                        ),
                        Text(
                          'Delivery ${widget.order.time}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Container(
                width: screenWidth,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xff888888),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 22),
                    Text(
                      'Status: The courier is delivering.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: const BoxDecoration(
                    color: Color(0xffF8F0E8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: getDocImage(),
                  ),
                ),
              ),
              GestureDetector(
                  onTap: () {
                    widget.order.status = 'Finished';
                    MaterialPageRoute route = MaterialPageRoute(
                      builder: (context) => const FinalPage(),
                    );
                    routes.add(route);
                    Navigator.push(
                      context,
                      route,
                    );
                  },
                  child: SizedBox(
                    width: screenWidth,
                    height: 52,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xffFE8E14),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(width: 10.0),
                            const Text(
                              'Confirm Delivery',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: screenWidth - 190,
                            ),
                            Image.asset("images/icon-arrow.png")
                          ]),
                    ),
                  )),
            ],
          ),
        ));
  }
}
