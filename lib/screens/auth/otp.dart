import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pinput/pinput.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/shared_prefernces.dart';
import 'package:rhyno_app/screens/auth/set_profile.dart';
import 'package:rhyno_app/screens/home.dart';

class Otp extends StatefulWidget {
  final String phoneNumber;
  const Otp({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  // Theme for pinput
  final defaultPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: const TextStyle(
        fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
    decoration: BoxDecoration(
      border: Border.all(color: c2),
      borderRadius: BorderRadius.circular(10),
    ),
  );

  bool isLoading = true; //loading state of page
  String otp = "";
  String verificationId = "verificationId";
  bool buttonDisabled = false;
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    sendVerification();
    super.initState();
  }

  //this function sends otp to given number when the page loads
  void sendVerification() async {
    await auth.verifyPhoneNumber(
      phoneNumber: '+91${widget.phoneNumber}',
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException exception) {
        if (exception.code == 'invalid-phone-number') {
          Fluttertoast.showToast(msg: 'Invalid Phone Number');
          Navigator.pop(context);
        }
      },
      codeSent: (String id, int? resendToken) async {
        setState(() {
          verificationId = id;
          isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  //this function verifies the entered otp and register the user
  void verifyCode() async {
    //disable button so that user does not send multiple requests
    setState(() {
      buttonDisabled = true;
    });
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: otp);
    try {
      await auth.signInWithCredential(credential).then((value) async {
        //set userId in localstorage and move to set profile page
        await SPMethods().setUserId(value.user!.uid);
        await SPMethods().setPhoneNumber(widget.phoneNumber);
        //Check if the user is already registered
        await DatabaseMethods()
            .findUserWithPhoneNumber(widget.phoneNumber)
            .then((v) {
          if (v.isEmpty) {
            //if not - create user profile
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SetProfile()),
                (route) => false);
          } else {
            //if yes - move to home page
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
                (route) => false);
          }
        });
      });
    } on FirebaseAuthException catch (err) {
      //in case of any error
      Fluttertoast.showToast(msg: '${err.message}');
      setState(() {
        buttonDisabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Loading()
        : Scaffold(
            appBar: AppBar(
              shadowColor: Colors.transparent,
              backgroundColor: Colors.transparent,
            ),
            backgroundColor: backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Verification',
                      style: TextStyle(
                          color: c1, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Enter the code sent to',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: c1,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '+91 ${widget.phoneNumber}',
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                          color: c1, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 16),
                      child: Pinput(
                        length: 6,
                        defaultPinTheme: defaultPinTheme,
                        onChanged: (pin) => {
                          setState(() {
                            otp = pin;
                          })
                        },
                      )),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: buttonDisabled
                        ? const CircularProgressIndicator(
                            color: c2,
                          )
                        : MaterialButton(
                            color: c2,
                            onPressed: buttonDisabled
                                ? () {}
                                : () {
                                    verifyCode();
                                  },
                            child: const Text('Verify'),
                          ),
                  )
                ],
              ),
            ),
          );
  }
}
