import 'package:flutter/material.dart';
import 'package:rhyno_app/components/custom_modal.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/components/notification_dot.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/shared_prefernces.dart';
import 'package:rhyno_app/screens/book_vehicle.dart';
import 'package:rhyno_app/screens/bookings.dart';
import 'package:rhyno_app/screens/more.dart';
import 'package:rhyno_app/screens/notifications.dart';
import 'package:rhyno_app/screens/profile.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  String userId = '';
  String adminNumber = "";

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    super.initState();
    getAdminNumber();
    getUserId();
  }

  getAdminNumber() async {
    await DatabaseMethods().getAdminNumber().then((value) {
      setState(() {
        adminNumber = value;
      });
    });
  }

  void getUserId() async {
    await SPMethods().getUserId().then((value) {
      setState(() {
        userId = value;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return isLoading
        ? const Loading()
        : Scaffold(
            body: Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(5))),
                backgroundColor: appBarColor,
                elevation: 0,
                title: Image.asset(
                  'assets/images/logo.png',
                  height: width / 8,
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              callAdminModal();
                            },
                            icon: const Icon(
                              Icons.call,
                              color: c2,
                            )),
                        // notification(),
                        IconButton(
                            onPressed: () async {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Profile(userId: userId)));
                            },
                            icon: const Icon(
                              Icons.person,
                              color: c2,
                            )),
                      ],
                    ),
                  ),
                ],
                bottom: navbar(),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  BookVehicle(userId: userId, tabController: _tabController),
                  Bookings(
                    userId: userId,
                  ),
                  More(userId: userId)
                ],
              ),
            ),
          );
  }

  PreferredSize navbar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            labelColor: backgroundColor,
            unselectedLabelColor: c1,
            padding: const EdgeInsets.all(8),
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            controller: _tabController,
            indicator: BoxDecoration(
              color: c2,
              borderRadius: BorderRadius.circular(5),
            ),
            tabs: [
              Container(
                  alignment: Alignment.center,
                  height: 30,
                  child: const Text(
                    'Book',
                  )),
              Container(
                  alignment: Alignment.center,
                  height: 30,
                  child: const Text(
                    'Bookings',
                  )),
              Container(
                  alignment: Alignment.center,
                  height: 30,
                  child: const Text(
                    'More',
                  )),
            ],
          ),
        ),
      ),
    );
  }

  StreamBuilder<dynamic> notification() {
    return StreamBuilder(
      stream: DatabaseMethods().getNotifications(userId, false),
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData && snapshot.data.docs.length > 0
            ? Stack(
                children: [
                  IconButton(
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Notifications(
                                      userId: userId,
                                    )));
                      },
                      icon: const Icon(
                        Icons.notifications,
                        color: c2,
                      )),
                  const Positioned(right: 10, top: 10, child: NotifationDot())
                ],
              )
            : IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Notifications(
                                userId: userId,
                              )));
                },
                icon: const Icon(
                  Icons.notifications,
                  color: c2,
                ));
      },
    );
  }

  callAdminModal() {
    showDialog(
        context: context,
        builder: (context) {
          return CustomModal(
              onSubmit: () async {
                Uri url = Uri.parse('tel:$adminNumber');
                if (!await launchUrl(url)) {
                  throw 'Could not launch $url';
                }
              },
              onCancel: () {
                Navigator.pop(context);
              },
              title: 'Call Admin',
              content: "Are you sure you want to call the admin?");
        });
  }
}
