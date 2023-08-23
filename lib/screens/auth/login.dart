import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rhyno_app/components/custom_text_field.dart';
import 'package:rhyno_app/components/filler.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/screens/auth/otp.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  //controller for phoneNumber
  TextEditingController phoneNumberController = TextEditingController();
  bool buttonDisabled = false;

  bool validateNumber(String number) {
    String regexPattern = r'^(?:[+0][1-9])?[0-9]{10}$';
    var regExp = RegExp(regexPattern);

    if (number.isEmpty) {
      return false;
    } else if (regExp.hasMatch(number)) {
      return true;
    }
    return false;
  }

  void login() async {
    setState(() {
      buttonDisabled = true;
    });
    //update phoneNumber in localstorage and move to otp screen
    if (validateNumber(phoneNumberController.text)) {
      //checking user limit for new users
      final userLimit = await DatabaseMethods().getUserLimit();
      final users = await DatabaseMethods().getNumberOfUsers();
      final user = await DatabaseMethods()
          .findUserWithPhoneNumber(phoneNumberController.text);

      if (user.isEmpty && userLimit <= users) {
        Fluttertoast.showToast(msg: "Can't Log in. User limit reached.");
        setState(() {
          buttonDisabled = false;
        });
        return;
      }

      Fluttertoast.showToast(msg: 'Sending OTP');
      //Navigating to OTP screen
      // ignore: use_build_context_synchronously
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Otp(
                    phoneNumber: phoneNumberController.text,
                  )));
    } else {
      Fluttertoast.showToast(msg: 'Invalid Phone Number');
    }
    setState(() {
      buttonDisabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: width / 1.5,
                  )),
            ),
            Column(
              children: [
                CustomTextField(
                    controller: phoneNumberController,
                    type: TextInputType.number,
                    placeholder: 'Enter 10-digit Mobile Number'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: buttonDisabled
                      ? const Center(
                          child: CircularProgressIndicator(color: c2),
                        )
                      : MaterialButton(
                          color: c2,
                          child: const Text('Verify'),
                          onPressed: () {
                            login();
                          },
                        ),
                ),
              ],
            ),
            const Filler()
          ],
        ),
      ),
    );
  }
}
