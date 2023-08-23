import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DatabaseMethods {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;

  Future createUserProfile(
      String name, String phoneNumber, String userId) async {
    //user model
    Map<String, dynamic> user = {
      "name": name,
      "profileImage": '',
      "licenseImage": '',
      "identityCardImage": '',
      "phoneNumber": phoneNumber,
      "securityDeposit": 0,
      "balance": 0,
      "verification": 'pending',
      "verifiedItems": {"drivingLicense": 'pending', "identityCard": 'pending'},
      "location": {"latitude": 0, "longitude": 0},
      "isRiding": false
    };

    await firestore.collection('users').doc(userId).set(user).then((value) {
      Fluttertoast.showToast(msg: 'User Registered Successfully');
    }).onError((error, stackTrace) {
      Fluttertoast.showToast(msg: 'User Registration Failed!');
    });
  }

  updateImage(String userId, file, String fileName) async {
    final filePath = 'users/$userId/$fileName';

    await storage.ref(filePath).putFile(file);

    await storage.ref(filePath).getDownloadURL().then((value) async {
      await firestore.collection('users').doc(userId).update({fileName: value});
    });
  }

  getVerificationStatus(userId) async {
    return (await firestore.collection('users').doc(userId).get())
        .data()!['verifiedItems'];
  }

  changeVerificationStatus(String userId, verifiedItems) async {
    await firestore
        .collection('users')
        .doc(userId)
        .update({"verifiedItems": verifiedItems, "verification": "pending"});
  }

  findUserWithPhoneNumber(String phoneNumber) async {
    var user = {};
    await firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        user = value.docs[0].data();
      }
    });
    return user;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserSnapshots(
      String userId) {
    return firestore.collection('users').doc(userId).snapshots();
  }

  getUserName(userId) async {
    return (await firestore.collection('users').doc(userId).get())['name'];
  }

  Future getUserBalance(String userId) async {
    return {
      'balance': (await firestore.collection('users').doc(userId).get())
          .data()!['balance'],
      'securityDeposit': (await firestore.collection('users').doc(userId).get())
          .data()!['securityDeposit']
    };
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getVehicleSnapshots(
      String vehicleId) {
    return firestore.collection('vehicles').doc(vehicleId).snapshots();
  }

  Future getCurrentRate() async {
    return (await firestore.collection('config').get()).docs[0]['currentRate'];
  }

  Future getBufferTime() async {
    return (await firestore.collection('config').get()).docs[0]['bufferTime'];
  }

  Future getUserLimit() async {
    return (await firestore.collection('config').get()).docs[0]['userLimit'];
  }

  Future getAdminNumber() async {
    return (await firestore.collection('config').get()).docs[0]['adminNumber'];
  }

  Future getMinSecurityDeposit() async {
    return (await firestore.collection('config').get()).docs[0]
        ['minSecurityDeposit'];
  }

  getNumberOfUsers() async {
    return (await firestore.collection('users').get()).docs.length;
  }

  // bookVehicle(DateTime startTime, DateTime endTime) async {
  //   final vehicleList = await firestore.collection('vehicles').get();
  //   final bufferTime = Duration(minutes: await getBufferTime());
  //   for (int i = 0; i < vehicleList.docs.length; i++) {
  //     bool found = true;
  //     final vehicle = vehicleList.docs[i];
  //     final bookingList =
  //         await firestore.collection('vehicles/${vehicle.id}/bookings').get();
  //     if (bookingList.docs.isEmpty) {
  //       if (startTime.isAfter(vehicle['availableBy'].toDate())) {
  //         return vehicle.id;
  //       } else {
  //         continue;
  //       }
  //     }
  //     for (int j = 0; j < bookingList.docs.length; j++) {
  //       final booking = bookingList.docs[j];

  //       if ((startTime.isAfter(booking['startTime'].toDate()) &&
  //               startTime
  //                   .isBefore(booking['endTime'].toDate().add(bufferTime))) ||
  //           (endTime.isAfter(booking['startTime'].toDate()) &&
  //                   endTime.isBefore(
  //                       booking['endTime'].toDate().add(bufferTime)) ||
  //               (booking['startTime'].toDate().isAfter(startTime) &&
  //                   booking['startTime'].toDate().isBefore(endTime)) ||
  //               (booking['endTime']
  //                       .toDate()
  //                       .add(bufferTime)
  //                       .isAfter(startTime) &&
  //                   booking['endTime']
  //                       .toDate()
  //                       .add(bufferTime)
  //                       .isBefore(endTime)))) {
  //         found = false;
  //         break;
  //       }
  //     }
  //     if (found) {
  //       return vehicle.id;
  //     }
  //   }

  //   return '';
  // }

  bookVehicle(DateTime startTime, DateTime endTime, double distance) async {
    double bufferDistance = 10;
    final vehicleList = await firestore
        .collection('vehicles')
        .where('kmsLeft', isGreaterThanOrEqualTo: distance + bufferDistance)
        .orderBy('kmsLeft')
        .get();
    if (vehicleList.docs.isNotEmpty) {
      for (int i = 0; i < vehicleList.docs.length; i++) {
        final vehicle = vehicleList.docs[i];
        if (startTime.isAfter(vehicle['availableBy'].toDate())) {
          return vehicle.id;
        }
      }
    }
    return '';
  }

  Future getVehicleAvailability() async {
    return (await firestore.collection('vehicles').orderBy('availableBy').get())
        .docs[0]['availableBy'];
  }

  Future confirmBooking(
      String userId,
      String vehicleId,
      String phoneNumber,
      DateTime startTime,
      int bufferTime,
      DateTime endTime,
      int approxDistance,
      double duration,
      double fare,
      balance) async {
    final bookingDocRef = firestore.collection('bookings').doc();
    await bookingDocRef.set({
      'userId': userId,
      'vehicleId': vehicleId,
      'phoneNumber': phoneNumber,
      'requestTime': startTime,
      'startTime': startTime,
      'endTime': endTime,
      'approxDistance': approxDistance,
      'fare': fare,
      'status': 'active',
      'duration': duration,
      'approved': false,
      'endRideRequest': false
    }).then((value) async {
      await firestore
          .collection('vehicles/$vehicleId/bookings')
          .doc(bookingDocRef.id)
          .set({
        'startTime': startTime,
        'endTime': endTime,
      });
      final availableBy = (await firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get())['availableBy'];
      await firestore.collection('vehicles').doc(vehicleId).update({
        // 'available': false,
        'availableBy': endTime
                .add(Duration(minutes: bufferTime))
                .isAfter(availableBy.toDate())
            ? endTime.add(Duration(minutes: bufferTime))
            : availableBy.toDate()
      });
    });
    await sendStartRideRequest(bookingDocRef.id, userId);
    await firestore.collection('users').doc(userId).update({'isRiding': true});
  }

  getAllBookings(userId, status) {
    return firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  cancelBooking(bookingId, booking) async {
    int timeLeft = booking['endTime']
        .toDate()
        .difference(DateTime.now())
        .inMinutes
        .toInt();
    int bufferTime = await getBufferTime();
    DateTime availableBy = booking['endTime']
        .toDate()
        .subtract(Duration(minutes: timeLeft))
        .subtract(Duration(minutes: bufferTime));

    await firestore
        .collection('vehicles')
        .doc(booking['vehicleId'])
        .update({'availableBy': availableBy});

    await firestore
        .collection('users')
        .doc(booking['userId'])
        .update({'isRiding': false});
    await firestore.collection('bookings').doc(bookingId).delete();

    await firestore
        .collection('vehicles')
        .doc(booking['vehicleId'])
        .collection('bookings')
        .doc(bookingId)
        .delete();
    final reqList = (await firestore
            .collection('requests')
            .where('bookingId', isEqualTo: bookingId)
            .get())
        .docs;
    for (var element in reqList) {
      await firestore.collection('requests').doc(element.id).delete();
    }
  }

  updateUserBalance(userId, balance, amount) async {
    await firestore
        .collection('users')
        .doc(userId)
        .update({'balance': balance + amount});
  }

  rechargeUserBalance(userId, user, amount) async {
    final minSecurityDeposit = await getMinSecurityDeposit();
    final securityDepositLeft = minSecurityDeposit - user['securityDeposit'];
    if (amount > securityDepositLeft) {
      var amountLeft = amount - securityDepositLeft;
      await firestore.collection('users').doc(userId).update({
        'securityDeposit': user['securityDeposit'] + securityDepositLeft,
        'balance': user['balance'] + amountLeft
      });
    } else {
      await firestore.collection('users').doc(userId).update({
        'securityDeposit': amount,
      });
    }
  }

  updateUserLocation(userId, lat, long) async {
    return firestore.collection('users').doc(userId).update({
      "location": {'latitude': lat, 'longitude': long}
    });
  }

  savePaymentDetails(orderId, paymentId, userId, amount) async {
    await firestore.collection('transactions').doc().set({
      "paymentId": paymentId,
      "userId": userId,
      "amount": int.parse(amount),
      "time": DateTime.now()
    });
  }

  getNotifications(userId, seen) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('seen', isEqualTo: seen)
        .orderBy('time', descending: true)
        .snapshots();
  }

  seenNotification(id) async {
    await firestore.collection('notifications').doc(id).update({"seen": true});
  }

  sendEndRideRequest(bookingId, userId) async {
    final name = await getUserName(userId);
    final doc = firestore.collection('requests').doc();
    await doc.set({
      "type": "end",
      "body": "$name has requested to end the ride.",
      "time": DateTime.now(),
      "seen": false,
      "bookingId": bookingId,
    });

    await firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'endRideRequest': true});
  }

  sendStartRideRequest(bookingId, userId) async {
    final name = await getUserName(userId);
    final doc = firestore.collection('requests').doc();
    await doc.set({
      "type": "start",
      "body": "$name has requested to start the ride.",
      "time": DateTime.now(),
      "seen": false,
      "bookingId": bookingId,
    });
  }

  getTransactions(userId) async {
    return await firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();
  }

  getTermsAndConditionsLink() async {
    return (await firestore.collection('config').get()).docs[0]['tncLink'];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getVehiclesList() {
    return firestore
        .collection('vehicles')
        .orderBy('availableBy')
        .snapshots();
  }
}
