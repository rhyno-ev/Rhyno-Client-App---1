import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/helper_functions.dart';

class Vehicle extends StatefulWidget {
  final String vehicleId;
  const Vehicle({Key? key, required this.vehicleId})
      : super(key: key);

  @override
  State<Vehicle> createState() => _VehicleState();
}

class _VehicleState extends State<Vehicle> {
  final rowSpacer = const TableRow(children: [
    SizedBox(
      height: 16,
    ),
    SizedBox(
      height: 16,
    )
  ]);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Vehicle'),
        backgroundColor: appBarColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: StreamBuilder(
              stream: DatabaseMethods().getVehicleSnapshots(widget.vehicleId),
              builder: (context, AsyncSnapshot snapshot) {
                final vehicle = snapshot.data;
                if (snapshot.hasData) {
                  return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: width / 2,
                              width: width / 2,
                              decoration: BoxDecoration(
                                  border: Border.all(width: 2, color: c2),
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                      image:
                                          NetworkImage(vehicle['vehicleImage']),
                                      fit: BoxFit.cover)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    vehicle['name'],
                                    style: const TextStyle(
                                        color: c2,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    vehicle['code'],
                                    style: const TextStyle(
                                        color: c1,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            vehicleStatus(vehicle),
                            Container(
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Specifications',
                                  style: TextStyle(
                                      color: c1,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                )),
                            specsTable(vehicle),
                          ],
                        ),
                      );
                } else {
                  return const Center(
                        child: CircularProgressIndicator(
                          color: c2,
                        ),
                      );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Table vehicleStatus(vehicle) {
    return Table(
      children: [
        rowSpacer,
        TableRow(children: [
          const Text('Available By',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            DateTime.now().isBefore(vehicle['availableBy'].toDate()) ? convertTimestamp(vehicle['availableBy']) : 'Now',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        TableRow(children: [
          const Text('Charge Left',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${vehicle['chargeLeft']} % (${vehicle['kmsLeft']} kms)',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer
      ],
    );
  }

  Table specsTable(vehicle) {
    return Table(
      children: [
        rowSpacer,
        TableRow(children: [
          const Text('Model',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            vehicle['model'],
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
        TableRow(children: [
          const Text('Range',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${vehicle['range']} kms',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
        TableRow(children: [
          const Text('Motor Type',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${vehicle['motorType']}',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
        TableRow(children: [
          const Text('Battery',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${vehicle['batteryCapacity']} Ah',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
        TableRow(children: [
          const Text('Charging Time',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${vehicle['chargingTime']} hours',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
      ],
    );
  }
}
