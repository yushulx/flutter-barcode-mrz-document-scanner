import 'package:delivery/barcode_scan_page.dart';
import 'package:delivery/delivery_page.dart';
import 'package:delivery/profile_page.dart';
import 'package:delivery/global.dart';
import 'package:flutter/material.dart';

import 'data/order_data.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
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
              'Assigned to Me',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Image.asset(
                "images/icon-profile.png",
                width: 24,
                height: 24,
              ),
              onPressed: () {
                MaterialPageRoute route = MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                );
                routes.add(route);
                Navigator.push(
                  context,
                  route,
                );
              },
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  MaterialPageRoute route = MaterialPageRoute(
                    builder: (context) => const BarcodeScanPage(),
                  );
                  routes.add(route);
                  await Navigator.push(
                    context,
                    route,
                  );
                  setState(() {});
                },
                icon: Image.asset(
                  "images/icon-scan-barcode.png",
                ),
              )
            ],
          ),
          body: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return MyCustomWidget(order: orders[index]);
              }),
        ));
  }
}

class MyCustomWidget extends StatelessWidget {
  final OrderData order;

  const MyCustomWidget({super.key, required this.order});

  Widget showStatus() {
    if (order.status == 'Assigned') {
      return Text(
        order.status!,
        style: const TextStyle(
          color: Color(0xff25C130),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (order.status == 'Started') {
      return Text(
        order.status!,
        style: const TextStyle(
          color: Color(0xff609EEF),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        order.status!,
        style: const TextStyle(
          color: Color(0xffF28C3E),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
        onTap: () {
          MaterialPageRoute route = MaterialPageRoute(
            builder: (context) => DeliveryPage(
              order: order,
            ),
          );
          routes.add(route);
          Navigator.push(
            context,
            route,
          );
        },
        child: Column(
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
                        'Order ID:${order.id}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: screenWidth - 278,
                      ),
                      showStatus(),
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
                        '${order.address}',
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
                        'Delivery ${order.time}',
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
            )
          ],
        ));
  }
}
