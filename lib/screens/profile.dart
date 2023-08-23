import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rhyno_app/components/custom_action_button.dart';
import 'package:rhyno_app/components/custom_modal.dart';
import 'package:rhyno_app/components/custom_text_field.dart';
import 'package:rhyno_app/components/filler.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/auth.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/shared_prefernces.dart';
import 'package:rhyno_app/screens/auth/login.dart';
import 'package:rhyno_app/screens/update_profile.dart';

class Profile extends StatefulWidget {
  final String userId;
  const Profile({Key? key, required this.userId}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController amountController = TextEditingController();
  final Razorpay _razorpay = Razorpay();
  Map user = {};
  bool isLoading = true;
  double minSecurityDeposit = 1000;

  @override
  void initState() {
    getMinSecurityDeposit();
    // activateRazorpay();
    getUserDetails();
    super.initState();
  }

  void getMinSecurityDeposit() async {
    await DatabaseMethods().getMinSecurityDeposit().then((value){
      setState(() {
        minSecurityDeposit = value;
      });
    });
  }

  void getUserDetails() async {
    String userId = widget.userId;
    DatabaseMethods().getUserSnapshots(userId).listen((event) {
      if (mounted) {
        setState(() {
          user = event.data()!;
          isLoading = false;
        });
      }
    });
  }

  // void activateRazorpay() {
  //   _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  //   _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  //   _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  // }

  // void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  //   Fluttertoast.showToast(msg: 'Payment Successful!');
  //   DatabaseMethods().rechargeUserBalance(
  //       widget.userId, user, int.parse(amountController.text));
  //   DatabaseMethods().savePaymentDetails(response.orderId, response.paymentId,
  //       widget.userId, amountController.text);
  // }

  // void _handlePaymentError(PaymentFailureResponse response) {
  //   // Do something when payment fails
  // }

  // void _handleExternalWallet(ExternalWalletResponse response) {
  //   // Do something when an external wallet is selected
  // }

  // void openRazorpay() {
  //   if (int.parse(amountController.text) <= 0) {
  //     Fluttertoast.showToast(msg: 'Enter a valid amount');
  //     return;
  //   }
  //   var options = {
  //     'key': rzp_test_key,
  //     'amount': int.parse(amountController.text) *
  //         100, //in the smallest currency sub-unit.
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

  // @override
  // void dispose() {
  //   super.dispose();
  //   _razorpay.clear(); // Removes all listeners
  // }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return isLoading
        ? const Loading()
        : Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: appBarColor,
              title: const Text('Profile'),
              actions: [
                TextButton(
                    onPressed: () async {
                      await AuthMethods().signout();
                      await SPMethods().removeAllData();

                      // ignore: use_build_context_synchronously
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Login()),
                          (route) => false);
                    },
                    child: const Text(
                      'Signout',
                      style: TextStyle(color: c2),
                    ))
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            floatingActionButton: CustomActionButton(
                onPressed: () {
                  paymentModal();
                  // rechargeAmountModel();
                },
                title: 'Recharge Balance',
                buttonDisabled: false),
            body: SafeArea(
                child: SingleChildScrollView(
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      width: width,
                      child: Column(
                        children: [
                          Container(
                            width: width / 2,
                            height: width / 2,
                            decoration: BoxDecoration(
                                border: Border.all(width: 2, color: c2),
                                borderRadius: BorderRadius.circular(100),
                                image: DecorationImage(
                                    image: NetworkImage(user['profileImage']),
                                    fit: BoxFit.cover)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              user['name'],
                              style: const TextStyle(
                                  color: c2,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Container(
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Information',
                                style: TextStyle(
                                    color: c1,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              )),
                          userDetails(),
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Verification',
                                style: TextStyle(
                                    color: c1,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24),
                              )),
                          verifiedItems(),
                          if (user['verification'] == 'discarded')
                            MaterialButton(
                              color: c2,
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => UpdateProfile(
                                            user: user, userId: widget.userId)));
                              },
                              child: const Text('Update Documents',
                                  style: TextStyle(color: backgroundColor)),
                            ),
                            const Filler()
                        ],
                        
                      )),
                )),
          );
  }

  void rechargeAmountModel() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            title: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text('Recharge', style: TextStyle(color: c1),),
            ),
            content: CustomTextField(
              placeholder: 'Enter Amount',
              controller: amountController,
              type: TextInputType.number,
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: c1),
                  )),
              TextButton(
                  onPressed: () {
                    // openRazorpay();
                    Navigator.pop(context);
                  },
                  child: const Text('Recharge', style: TextStyle(color: c2)))
            ],
          );
        });
  }

  final rowSpacer = const TableRow(children: [
    SizedBox(
      height: 16,
    ),
    SizedBox(
      height: 16,
    )
  ]);

  Table userDetails() {
    return Table(
      children: [
        rowSpacer,
        TableRow(children: [
          const Text('Phone Number',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            user['phoneNumber'],
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
        TableRow(children: [
          const Text('Balance',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '\u{20B9} ${user['balance']}',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
        TableRow(children: [
          const Text('Security Deposit',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '\u{20B9} ${user['securityDeposit']}\n(\u{20B9}$minSecurityDeposit refundable)',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
      ],
    );
  }

  Table verifiedItems() {
    return Table(
      children: [
        rowSpacer,
        TableRow(children: [
          const Text('Driving License',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${user['verifiedItems']['drivingLicense']}',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
        TableRow(children: [
          const Text('Identity Card',
              style: TextStyle(
                  color: c1, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${user['verifiedItems']['identityCard']}',
            style: const TextStyle(
                color: c2, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          )
        ]),
        rowSpacer,
      ],
    );
  }

  paymentModal() {
    showDialog(
        context: context,
        builder: (context) {
          return CustomModal(
              onSubmit: () {
                Navigator.pop(context);
              },
              onCancel: () {
                Navigator.pop(context);
              },
              title: 'Payment',
              content:
                  'Payment gateway will be added soon.');
        });
  }
}
