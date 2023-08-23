import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rhyno_app/components/custom_modal.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/helper_functions.dart';

class Bookings extends StatefulWidget {
  final String userId;
  const Bookings({Key? key, required this.userId}) : super(key: key);

  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  String bookingType = 'active';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 8),
            child: Text(
              'Booking Status',
              style: TextStyle(color: c2, fontWeight: FontWeight.bold),
            ),
          ),
          bookingTypeButton(width),
          Expanded(child: bookingStreamWidget(width))
        ],
      )),
    );
  }

  Widget bookingTypeButton(width) {
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
                bookingType = 'active';
              });
            },
            child: Container(
              alignment: Alignment.center,
              height: width / 10,
              width: width / 3,
              decoration: BoxDecoration(
                  color: bookingType == 'active'
                      ? backgroundColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Active',
                style: TextStyle(
                    color: bookingType == 'active' ? c2 : backgroundColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                bookingType = 'completed';
              });
            },
            child: Container(
              alignment: Alignment.center,
              height: width / 10,
              width: width / 3,
              decoration: BoxDecoration(
                  color: bookingType == 'completed'
                      ? backgroundColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Completed',
                style: TextStyle(
                    color: bookingType == 'completed' ? c2 : backgroundColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget bookingStreamWidget(width) {
    return StreamBuilder(
      stream: DatabaseMethods().getAllBookings(widget.userId, bookingType),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loading();
        }
        return snapshot.hasData
            ? snapshot.data.docs.length > 0
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                      final booking = snapshot.data.docs[index];
                      return bookingListTile(width, booking);
                    },
                  )
                : Center(
                    child: Column(
                      children: const [
                        Icon(
                          Icons.notes_rounded,
                          color: c1,
                          size: 100,
                        ),
                        Text(
                          'No booking found',
                          style: TextStyle(color: c1),
                        ),
                      ],
                    ),
                  )
            : const Loading();
      },
    );
  }

  Widget bookingListTile(width, booking) {
    return StreamBuilder(
      stream: DatabaseMethods().getVehicleSnapshots(booking['vehicleId']),
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? Container(
                // height: width / 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: !booking['approved']
                    ? const EdgeInsets.only(
                        left: 16, top: 16, bottom: 8, right: 16)
                    : const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: appBarColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${snapshot.data['name']}-${snapshot.data['code']}',
                              style: const TextStyle(
                                  color: c2,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            Text(
                              'Start Time: ${convertTimestamp(booking["startTime"])}',
                              style: const TextStyle(
                                  color: c2,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                            Text(
                              'End Time: ${convertTimestamp(booking["endTime"])}',
                              style: const TextStyle(
                                  color: c2,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                            Text(
                              'Fare: \u{20B9}${booking['fare']}',
                              style: const TextStyle(
                                  color: c1,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              snapshot.data['vehicleImage'],
                              height: width / 5,
                              width: width / 5,
                            ))
                      ],
                    ),
                    if (bookingType == 'active')
                      booking['approved']
                          ? Center(
                              child: !booking['endRideRequest']
                                  ? TextButton(
                                      child: const Text(
                                        'Request to End Ride',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        endRideModal(booking);
                                      },
                                    )
                                  : TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        'Waiting for admin confirmation',
                                        style: TextStyle(
                                            color: c2,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                            )
                          : Center(
                              child: TextButton(
                                child: const Text(
                                  'Cancel Booking',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  cancelRideModal(booking);
                                },
                              ),
                            )
                  ],
                ),
              )
            : const SizedBox();
      },
    );
  }

  cancelRideModal(booking) {
    showDialog(
        context: context,
        builder: (context) {
          return CustomModal(
              onSubmit: () async {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                await DatabaseMethods()
                    .cancelBooking(booking.id, booking)
                    .then((v) {
                  Fluttertoast.showToast(msg: 'Booking Cancelled');
                });
                if (await FlutterBackgroundService().isServiceRunning()) {
                  FlutterBackgroundService()
                      .sendData({'action': 'stopService'});
                }
              },
              onCancel: () {
                Navigator.pop(context);
              },
              title: 'Cancel Ride',
              content: 'Are you sure you want to cancel the ride?');
        });
  }

  endRideModal(booking) {
    showDialog(
        context: context,
        builder: (context) {
          return CustomModal(
              onSubmit: () async {
                DatabaseMethods()
                    .sendEndRideRequest(booking.id, booking['userId']);
                if (await FlutterBackgroundService().isServiceRunning()) {
                  FlutterBackgroundService()
                      .sendData({'action': 'stopService'});
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              onCancel: () {
                Navigator.pop(context);
              },
              title: 'End Ride',
              content: 'Are you sure you want to end the ride?');
        });
  }
}
