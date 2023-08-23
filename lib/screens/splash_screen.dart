import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/shared_prefernces.dart';
import 'package:rhyno_app/main.dart';
import 'package:rhyno_app/screens/auth/login.dart';
import 'package:rhyno_app/screens/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  //opacity of the logo
  var opacity = 0.0;

  //this function runs when the page loads
  @override
  void initState() {
    super.initState();
    redirect();
  }


  //this function redirects to home/login page after a shot animation
  void redirect() async {
    final phoneNumber = await SPMethods().getPhoneNumber();
    //changing opacity of the logo. duration: 0.5 sec
    await Future.delayed(const Duration(milliseconds: 500)).then((value) {
      setState(() {
        opacity = 1.0;
      });
    });

    await Future.delayed(const Duration(seconds: 2)).then((value) async {
      //checking for internet connection
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        await DatabaseMethods().findUserWithPhoneNumber(phoneNumber).then((v) {
          if (v.isEmpty) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const Login()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const Home()));
          }
        });
      } else {
        //exit the app if no internet found
        Fluttertoast.showToast(msg: 'No Internet Connection');
        await Future.delayed(const Duration(seconds: 2)).then((value) {
          exit(0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: width,),
              AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(seconds: 1),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: width / 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(seconds: 1),
                  child: Column(
                    children: const [
                      Text('Developed by,', style: TextStyle(color: c1,  fontWeight: FontWeight.bold),),
                      Text('Kumar Shashank', style: TextStyle(color: c2, fontWeight: FontWeight.bold),)
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
