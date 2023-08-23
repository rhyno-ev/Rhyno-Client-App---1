import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/helper_functions.dart';

class Notifications extends StatefulWidget {
  final String userId;
  const Notifications({Key? key, required this.userId}) : super(key: key);

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {

  List notificationIds = [];


  notificationBuilder(seen){
    return StreamBuilder(
      stream: DatabaseMethods().getNotifications(widget.userId, seen),
      builder: (context, AsyncSnapshot snapshot){
        return snapshot.hasData && snapshot.data.docs.length > 0 ? ListView.builder(
        itemCount: snapshot.data.docs.length,
        shrinkWrap: true,
        itemBuilder: (context, index){
          final notification = snapshot.data.docs[index];
          notificationIds.add(notification.id);
          return Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appBarColor,
              borderRadius: BorderRadius.circular(10)
            ),
            child: ListTile(
              title: Text(notification['body'], style: TextStyle(color: c2)),
              trailing: Text(convertTimestamp(notification['time']), textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: c1),),
            ),
          );
        },
      ): Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(seen ? 'No previous notifications.' : 'No new notifications.', style: TextStyle(color: c1),),
        ),
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: appBarColor,
        leading: IconButton(onPressed: (){
          for (var element in notificationIds) {
            DatabaseMethods().seenNotification(element);
          }
          Navigator.pop(context);
        }, icon: const Icon(Icons.arrow_back)),
      ),
    );
  }
}