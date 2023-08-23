import 'package:flutter/material.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/screens/vehicle.dart';
// import 'package:rhyno_app/screens/vehicle.dart';

class Vehicles extends StatefulWidget {
  const Vehicles({Key? key}) : super(key: key);

  @override
  State<Vehicles> createState() => _VehiclesState();
}

class _VehiclesState extends State<Vehicles> {
  bool isLoading = true;

  @override
  void initState() {
    setState(() {
      isLoading = false;
    });
    super.initState();
  }

  Widget vehicleTile(name, code, model, vehicleImage, vehicleId, availableBy) {
    return ListTile(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => Vehicle(vehicleId: vehicleId)));
      },
      leading: CircleAvatar(backgroundImage: NetworkImage(vehicleImage),),
      trailing: Icon(Icons.circle, size: 10, color: DateTime.now().isAfter(availableBy.toDate()) ? Colors.green : Colors.red,),
      title: Text(name, style: const TextStyle(color: c2),),
      subtitle: Text(code, style: const TextStyle(color: c1),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Loading()
        : Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: appBarColor,
              shadowColor: Colors.transparent,
              title: const Text('Vehicles', style: TextStyle(color: c2),),
            ),
            body: Column(
              children: [
                
                Expanded(
                  child: StreamBuilder(
                    stream: DatabaseMethods().getVehiclesList(),
                    builder: (context, AsyncSnapshot snapshot) {
                      return snapshot.hasData
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: snapshot.data.docs.length,
                              itemBuilder: (context, index) {
                                final vehicle = snapshot.data.docs[index];
                                return vehicleTile(vehicle['name'], vehicle['code'], vehicle['model'], vehicle['vehicleImage'], vehicle.id, vehicle['availableBy']);
                              },
                            )
                          : const Loading();
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
