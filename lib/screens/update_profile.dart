import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rhyno_app/components/custom_action_button.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';

class UpdateProfile extends StatefulWidget {
  final Map user;
  final String userId;
  const UpdateProfile({Key? key, required this.user, required this.userId})
      : super(key: key);

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  bool licenseImagePicked = false, identityCardImagePicked = false;
  late File licenseImageFile, identityCardImageFile;
  bool isLoading = true;
  bool buttonDisabled = false;
  Map verifiedItems = {
    "drivingLicense": "pending",
    "identityCard": "pending"
  };

  @override
  void initState() {
    super.initState();
    getVerificationStatus();
  }

  void getVerificationStatus() async {
    await DatabaseMethods().getVerificationStatus(widget.userId).then((value) {
      setState(() {
        verifiedItems = value;
        isLoading = false;
      });
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

  //show license preview
  void showDrivingLicense() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return SimpleDialog(
            backgroundColor: Colors.transparent,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(licenseImageFile),
              )
            ],
          );
        });
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
    setState(() {
      buttonDisabled = true;
    });

    try {
      showUploadingDialog();
      if(licenseImagePicked){
        await DatabaseMethods().updateImage(widget.userId, licenseImageFile, "licenseImage");
        verifiedItems['drivingLicense'] = "pending";
        await DatabaseMethods().changeVerificationStatus(widget.userId, verifiedItems);
      }
      if(identityCardImagePicked){
        await DatabaseMethods()
          .updateImage(widget.userId, identityCardImageFile, "identityCardImage");
        verifiedItems['identityCard'] = "pending";
        await DatabaseMethods().changeVerificationStatus(widget.userId, verifiedItems);
      }
      
      Fluttertoast.showToast(msg: 'Profile updated');
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
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
    if (isLoading) {
      return const Loading();
    } else {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          title: const Text(
            'Update Your Profile',
            style: TextStyle(color: c1),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: CustomActionButton(onPressed: () {
                              submitDetails();
                            }, title: 'Update', buttonDisabled: buttonDisabled),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8),
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Align(alignment: Alignment.centerLeft, child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Driving License', style: TextStyle(color: c2, fontWeight: FontWeight.bold),),
                  )),
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
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(width: 2, color: c2),
                            borderRadius: BorderRadius.circular(10),
                            image: licenseImagePicked
                                ? DecorationImage(
                                    image: FileImage(licenseImageFile),
                                    fit: BoxFit.cover)
                                : DecorationImage(
                                    image: NetworkImage(
                                        widget.user['licenseImage']),
                                    fit: BoxFit.cover)),
                      ),
                    ),
                  ),
                  const Align(alignment: Alignment.centerLeft, child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('College Identity Card', style: TextStyle(color: c2, fontWeight: FontWeight.bold),),
                  )),
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
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(width: 2, color: c2),
                            borderRadius: BorderRadius.circular(10),
                            image: identityCardImagePicked
                                ? DecorationImage(
                                    image: FileImage(identityCardImageFile),
                                    fit: BoxFit.cover)
                                : DecorationImage(
                                    image: NetworkImage(
                                        widget.user['identityCardImage']),
                                    fit: BoxFit.cover)),
                            ),
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
