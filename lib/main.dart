// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:location/location.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/shared_prefernces.dart';
import 'package:rhyno_app/screens/book_vehicle.dart';
import 'package:rhyno_app/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

void onStart() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final service = FlutterBackgroundService();
  service.setNotificationInfo(title: 'Rhyno', content: 'Running Location Service');
  service.onDataReceived.listen((event) {
    if (event!['action'] == 'stopService') {
      service.stopBackgroundService();
    }
  });

  final userId = await SPMethods().getUserId();
  Geolocator.getPositionStream().listen((locationData) {
    final latitude = double.parse(locationData.latitude.toStringAsFixed(3));
    final longitude = double.parse(locationData.longitude.toStringAsFixed(3));
    DatabaseMethods().updateUserLocation(userId, latitude, longitude);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const KeyboardDismisser(
      gestures: [GestureType.onTap],
      child: MaterialApp(
        home: SplashScreen(),
      ),
    );
  }
}
