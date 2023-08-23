import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rhyno_app/components/custom_action_button.dart';
import 'package:rhyno_app/components/custom_text_field.dart';
import 'package:rhyno_app/components/filler.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/shared_prefernces.dart';
import 'package:rhyno_app/screens/home.dart';

class SetProfile extends StatefulWidget {
  const SetProfile({Key? key}) : super(key: key);

  @override
  State<SetProfile> createState() => _SetProfileState();
}

class _SetProfileState extends State<SetProfile> {
  bool profileImagePicked = false, licenseImagePicked = false, identityCardImagePicked = false;
  late File profileImageFile, licenseImageFile, identityCardImageFile;
  late String phoneNumber, userId;
  bool isLoading = true;
  bool buttonDisabled = false;
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getData();
  }

  //get data from localstorage
  void getData() async {
    phoneNumber = await SPMethods().getPhoneNumber();
    userId = await SPMethods().getUserId();
    setState(() {
      isLoading = false;
    });
  }

  //pick image from gallery
  void pickImage(target) async {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);
    if (image != null) {
      switch (target) {
        case 'profileImage':
          setState(() {
            profileImagePicked = true;
            profileImageFile = File(image.path);
          });
          break;
        case 'licenseImage':
          setState(() {
            licenseImagePicked = true;
            licenseImageFile = File(image.path);
          });
          break;
        case 'identityCardImage':
          setState(() {
            identityCardImagePicked = true;
            identityCardImageFile = File(image.path);
          });
          break;
      }
    } else {
      Fluttertoast.showToast(msg: 'No file selected!');
    }
  }


  void showUploadingDialog() {
    showDialog(
        barrierColor: Colors.white.withOpacity(0.5),
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return SimpleDialog(
            backgroundColor: backgroundColor,
            children: [
              Column(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Uploading Images',
                      style: TextStyle(color: c1, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: c2,
                    ),
                  ),
                ],
              )
            ],
          );
        });
  }

  void submitDetails() async {
    if (nameController.text.length < 3) {
      Fluttertoast.showToast(
          msg: 'Invalid Name. Name must be at least 3 characters long.');
      return;
    }
    if (!profileImagePicked || !licenseImagePicked || !identityCardImagePicked) {
      Fluttertoast.showToast(msg: 'Please upload required images');
      return;
    }
    setState(() {
      buttonDisabled = true;
    });

    try {
      showUploadingDialog();
      await DatabaseMethods()
          .createUserProfile(nameController.text, phoneNumber, userId);
      await DatabaseMethods().updateImage(userId, profileImageFile, "profileImage");
      await DatabaseMethods().updateImage(userId, licenseImageFile, "licenseImage");
      await DatabaseMethods().updateImage(userId, identityCardImageFile, "identityCardImage");
      // ignore: use_build_context_synchronously
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Image Upload Failed');
      setState(() {
        buttonDisabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return isLoading ? const Loading() : Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          title: const Text(
            'Complete Your Profile',
            style: TextStyle(color: c1),
          ),
          automaticallyImplyLeading: false,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: CustomActionButton(onPressed: (){
          submitDetails();
        }, title: 'Submit', buttonDisabled: buttonDisabled),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8),
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      pickImage('profileImage');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: CircleAvatar(
                          radius: width / 4,
                          backgroundColor: c2,
                          child: !profileImagePicked
                              ? const Text('Click to upload Profile Photo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: backgroundColor,
                                      fontWeight: FontWeight.bold))
                              : Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(width: 2, color: c2),
                                      borderRadius: BorderRadius.circular(100),
                                      image: DecorationImage(
                                          image: FileImage(profileImageFile),
                                          fit: BoxFit.cover)),
                                )),
                    ),
                  ),
                  CustomTextField(
                      controller: nameController,
                      type: TextInputType.text,
                      placeholder: 'Enter Your Full Name'),
                  GestureDetector(
                    onTap: () {
                      pickImage('licenseImage');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: c2, borderRadius: BorderRadius.circular(10)),
                      width: width,
                      height: width / 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: !licenseImagePicked
                          ? const Center(
                              child: Text('Click to upload Driving License',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: backgroundColor,
                                      fontWeight: FontWeight.bold)),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                  border: Border.all(width: 2, color: c2),
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                      image: FileImage(licenseImageFile),
                                      fit: BoxFit.cover)),
                            ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      pickImage('identityCardImage');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: c2, borderRadius: BorderRadius.circular(10)),
                      width: width,
                      height: width / 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: !identityCardImagePicked
                          ? const Center(
                              child: Text('Click to upload College Identity Card',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: backgroundColor,
                                      fontWeight: FontWeight.bold)),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                  border: Border.all(width: 2, color: c2),
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                      image: FileImage(identityCardImageFile),
                                      fit: BoxFit.cover)),
                            ),
                    ),
                  ),
                  const Filler()
                ],
              ),
            ),
          ),
        ),
      );
  }
}
