import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:rhyno_app/components/custom_container.dart';
import 'package:rhyno_app/components/custom_modal.dart';
import 'package:rhyno_app/components/custom_text_field.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rhyno_app/helpers/helper_functions.dart';
import 'package:rhyno_app/main.dart';
import 'package:rhyno_app/screens/profile.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rhyno_app/screens/vehicles.dart';
import 'package:url_launcher/url_launcher.dart';

class BookVehicle extends StatefulWidget {
  final String userId;
  final TabController tabController;
  const BookVehicle(
      {Key? key, required this.userId, required this.tabController})
      : super(key: key);

  @override
  State<BookVehicle> createState() => _BookVehicleState();
}

class _BookVehicleState extends State<BookVehicle> {
  TextEditingController distanceController = TextEditingController();
  final Razorpay _razorpay = Razorpay();

  bool isLoading = true;
  String bookingMethod = 'now';
  bool buttonDisabled = false;

  //details
  double duration = 0.5;
  double requiredDistance = 0;
  double fare = 0;
  List currentRate = [];

  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();

  Map user = {};

  double minSecurityDeposit = 0;
  int bufferTime = 0;

  late PermissionStatus _permissionGranted;
  late LocationData _locationData;
  Location location = Location();
  late double lat;
  late double long;

  @override
  void initState() {
    super.initState();
    getMinSecurityDeposit();
    getBufferTime();
    getCurrentRate();
    getUserDetails();
    // activateRazorpay();
  }

  // void activateRazorpay() {
  //   _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  //   _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  //   _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  // }

  // void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  //   await DatabaseMethods()
  //       .updateUserBalance(
  //           widget.userId, user['balance'], fare - user['balance'])
  //       .then((v) {
  //     bookWithBookingMethod();
  //   });
  //   DatabaseMethods().savePaymentDetails(
  //       response.orderId, response.paymentId, widget.userId, fare);
  // }

  // void _handlePaymentError(PaymentFailureResponse response) {
  //   // Do something when payment fails
  // }

  // void _handleExternalWallet(ExternalWalletResponse response) {
  //   // Do something when an external wallet is selected
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  //   _razorpay.clear(); // Removes all listeners
  // }

  void getMinSecurityDeposit() async {
    await DatabaseMethods().getMinSecurityDeposit().then((value) {
      setState(() {
        minSecurityDeposit = value.toDouble();
      });
    });
  }

  void getBufferTime() async {
    await DatabaseMethods().getBufferTime().then((value) {
      setState(() {
        bufferTime = value;
      });
    });
  }

  void getUserDetails() async {
    String userId = widget.userId;
    DatabaseMethods().getUserSnapshots(userId).listen((event) {
      if (mounted) {
        setState(() {
          user = event.data()!;
        });
      }
    });
    setState(() {
      isLoading = false;
    });
  }

  void getCurrentRate() async {
    await DatabaseMethods().getCurrentRate().then((value) {
      setState(() {
        currentRate = value;
      });
    });
    calculatePrice();
  }

  void calculatePrice() async {
    int ind = ((duration - 0.01) * 2).toInt();
    setState(() {
      fare = currentRate[ind].toDouble();
    });
  }

  // void openRazorpay() {
  //   var options = {
  //     'key': rzp_test_key,
  //     'amount':
  //         (fare - user['balance']) * 100, //in the smallest currency sub-unit.
  //     'name': user['name'], // Generate order_id using Orders API
  //     'description': 'Rhyno EV',
  //     'timeout': 120, // in seconds
  //     'prefill': {
  //       'contact': user['phoneNumber'],
  //     }
  //   };
  //   try {
  //     _razorpay.open(options);
  //   } catch (err) {
  //     Fluttertoast.showToast(msg: 'Payment Failed!');
  //   }
  // }

  void bookWithBookingMethod() {
    if (bookingMethod == 'now') {
      book(DateTime.now(), DateTime.now());
    } else {
      book(startTime, endTime);
    }
  }

  void book(st, et) async {
    String userId = widget.userId;
    if (st.add(const Duration(minutes: 1)).isBefore(DateTime.now()) ||
        et.add(const Duration(minutes: 1)).isBefore(DateTime.now())) {
      Fluttertoast.showToast(msg: 'Invalid Time!');
      return;
    }

    if (user['isRiding']) {
      Fluttertoast.showToast(msg: 'You already have a booking.');
      return;
    }

    if (distanceController.text == '') {
      Fluttertoast.showToast(msg: 'Provide approximate distance');
      return;
    }
    if (user['verification'] == 'discarded') {
      discardedModal();
      return;
    }
    if (user['verification'] != 'verified') {
      Fluttertoast.showToast(msg: 'Your profile verification is pending.');
      return;
    }
    if (user['securityDeposit'] < minSecurityDeposit) {
      showLowBalanceModal(userId);

      return;
    }
    if (await getLocationPermission() == false) {
      Fluttertoast.showToast(msg: 'Grant location permission to continue');
      return;
    }
    getlocation();
    setState(() {
      buttonDisabled = true;
    });
    final vehicleId = await DatabaseMethods()
        .bookVehicle(st, et.add(Duration(minutes: (duration * 60).toInt())), double.parse(distanceController.text));
    if (vehicleId == '') {
      notAvailableModal();
      setState(() {
        buttonDisabled = false;
      });
      return;
    }
    if (user['balance'] >= fare) {
      try {
        await DatabaseMethods()
            .confirmBooking(
                userId,
                vehicleId,
                user['phoneNumber'],
                st,
                bufferTime,
                et.add(Duration(minutes: (duration * 60).toInt())),
                int.parse(distanceController.text),
                duration,
                fare,
                user['balance'])
            .then((value) {
          Fluttertoast.showToast(msg: 'Booking Requested');
          widget.tabController.index = 1;
        });
      } catch (err) {
        Fluttertoast.showToast(msg: 'Something went wrong!');
      }
    } else {
      showLowBalanceModal(userId);
    }
    setState(() {
      buttonDisabled = false;
    });
  }


  Future<dynamic> showLowBalanceModal(String userId) {
    return showDialog(
        context: context,
        builder: (context) {
          return CustomModal(
              onSubmit: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Profile(userId: userId)));
              },
              onCancel: () {
                Navigator.pop(context);
              },
              title: 'Low Balance',
              content: 'Kindly recharge.');
          //
        });
  }

  Future<bool> getLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locationModal();
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void getlocation() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterBackgroundService.initialize(onStart);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return isLoading
        ? const Loading()
        : Scaffold(
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: bookingMethod == 'advance'
                ? const SizedBox()
                : bookButton(width),
            backgroundColor: backgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 20, top: 8),
                            child: Text(
                              'Booking Type',
                              style: TextStyle(
                                  color: c2, fontWeight: FontWeight.bold),
                            ),
                          ),
                          bookingMethodButton(width),
                          bookingMethod == 'advance'
                              ? const Center(
                                  child: Text(
                                    'This feature will be available soon!',
                                    style: TextStyle(
                                        color: c2, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(left: 20, top: 8),
                                      child: Text(
                                        'Duration',
                                        style: TextStyle(
                                            color: c2,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showDurationModal(width);
                                      },
                                      child: CustomContainer(
                                        customChild: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('$duration  hr',
                                                style: const TextStyle(
                                                    color: c1,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            const Icon(
                                              Icons.arrow_drop_down_rounded,
                                              color: c1,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(left: 20, top: 8),
                                      child: Text(
                                        'Required Distance',
                                        style: TextStyle(
                                            color: c2,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    CustomTextField(
                                        controller: distanceController,
                                        type: TextInputType.number,
                                        placeholder:
                                            'Approximate Distance (km)'),
                                  ],
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  void discardedModal() {
    showDialog(
        context: context,
        builder: (context) {
          return CustomModal(
              onSubmit: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Profile(userId: widget.userId)));
              },
              onCancel: () {
                Navigator.pop(context);
              },
              title: 'Verification Failed',
              content:
                  'Some of your documents are discarded by the admin. Please upload again.');
        });
  }

  void notAvailableModal() {
    showDialog(
        context: context,
        builder: (context) {
          return CustomModal(
              onSubmit: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Vehicles()));
              },
              onCancel: () {
                Navigator.pop(context);
              },
              title: 'No vehicle available',
              content:
                  'No vehicles are available for the given time and distance. Press Okay to see the list of available vehicles.');
        });
  }

  showDurationModal(width) {
    final durationList = [];
    for (double i = 0.5; i <= currentRate.length / 2; i += 0.5) {
      durationList.add(i);
    }

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            title: const Center(
                child: Text('Select Duration', style: TextStyle(color: c1))),
            content: SizedBox(
              height: width,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...(durationList).map((e) {
                    return TextButton(
                        onPressed: () {
                          setState(() {
                            duration = e;
                          });
                          calculatePrice();
                          Navigator.pop(context);
                        },
                        child: Text(
                          '$e  hr',
                          style: const TextStyle(color: c2),
                        ));
                  })
                ],
              ),
            ),
          );
        });
  }

  Widget bookingMethodButton(width) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: width / 8,
      width: width,
      decoration:
          BoxDecoration(color: c2, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                bookingMethod = 'now';
                startTime = DateTime.now();
              });
            },
            child: Container(
              alignment: Alignment.center,
              height: width / 10,
              width: width / 3,
              decoration: BoxDecoration(
                  color: bookingMethod == 'now'
                      ? backgroundColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Now',
                style: TextStyle(
                    color: bookingMethod == 'now' ? c2 : backgroundColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                bookingMethod = 'advance';
                startTime = DateTime.now();
              });
            },
            child: Container(
              alignment: Alignment.center,
              height: width / 10,
              width: width / 3,
              decoration: BoxDecoration(
                  color: bookingMethod == 'advance'
                      ? backgroundColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Advance',
                style: TextStyle(
                    color: bookingMethod == 'advance' ? c2 : backgroundColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget startTimeButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 8),
          child: Text(
            'Start Time',
            style: TextStyle(color: c2, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
            onTap: () {
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2050),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: backgroundColor, onPrimary: c2),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          primary: backgroundColor, // button text color
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              ).then((date) {
                showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                        hour: DateTime.now().hour,
                        minute: DateTime.now().minute),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: backgroundColor, onPrimary: c2),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              primary: backgroundColor, // button text color
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    }).then((time) {
                  final newDate = date!
                      .add(Duration(hours: time!.hour, minutes: time.minute));
                  setState(() {
                    startTime = newDate;
                    endTime = newDate;
                  });
                });
              });
            },
            child: CustomContainer(
                customChild: Text(
              convertDateTime(startTime),
              style: const TextStyle(color: c1),
            ))),
      ],
    );
  }

  Container bookButton(double width) {
    return Container(
      width: width,
      height: width / 5,
      color: c2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fare: \u{20B9}$fare',
                    style: const TextStyle(
                        color: backgroundColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  children: [
                    const Text('(Available Balance:',
                        style: TextStyle(color: backgroundColor, fontSize: 12)),
                    const SizedBox(
                      width: 4,
                    ),
                    Text('\u{20B9}${user['balance']})',
                        style: const TextStyle(
                            color: backgroundColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))
                  ],
                )
              ],
            ),
          ),
          Container(
            width: width / 2.5,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: buttonDisabled || fare == 0
                ? const CircularProgressIndicator(
                    color: backgroundColor,
                  )
                : MaterialButton(
                    color: backgroundColor,
                    onPressed: () {
                      tncModal();
                    },
                    child: const Text(
                      'Book Now',
                      style: TextStyle(color: c2),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget dropdown(width, title, onTap) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
            color: c1.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          onTap: onTap,
          title: Text(title,
              style: const TextStyle(color: c1, fontWeight: FontWeight.bold)),
          trailing: const Icon(
            Icons.arrow_drop_down_rounded,
            color: c1,
          ),
        ),
      ),
    );
  }

  locationModal() {
    showDialog(
        context: context,
        builder: (context) {
          return CustomModal(
              onSubmit: () async {
                await Geolocator.openLocationSettings();
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              onCancel: () {
                Navigator.pop(context);
              },
              title: 'Location Permission',
              content: 'Turn on Location Service');
        });
  }

  tncModal() {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            backgroundColor: backgroundColor,
            title: const Text(
              'Terms of use',
              style: TextStyle(color: c2),
            ),
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    children: [
                      const Text("By clicking continue, you agree to the ", style: TextStyle(color: c1)),
                      GestureDetector(
                          onTap: () async {
                            final Uri tncLink = Uri.parse(await DatabaseMethods()
                                .getTermsAndConditionsLink());
                            if (!await launchUrl(tncLink)) {
                              throw 'Could not launch $tncLink';
                            }
                          },
                          child: const Text("liability transfer agreement ",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold))),
                      const Text("and ", style: TextStyle(color: c1)),
                      GestureDetector(
                        onTap: () async {
                            final Uri tncLink = Uri.parse(await DatabaseMethods()
                                .getTermsAndConditionsLink());
                            if (!await launchUrl(tncLink)) {
                              throw 'Could not launch $tncLink';
                            }
                          },
                          child: const Text("terms of use.",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold))),
                    ],
                  )
                  ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child:
                            const Text('Cancel', style: TextStyle(color: c1))),
                    TextButton(
                        onPressed: () {
                          bookWithBookingMethod();
                          Navigator.pop(context);
                        },
                        child: const Text('Continue', style: TextStyle(color: c2))),
                  ],
                ),
              ),
            ],
          );
        });
  }
}
