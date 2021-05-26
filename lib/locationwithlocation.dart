import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:share/share.dart';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: MyMap(),
      ),
    );
  }
}


class MyMap extends StatefulWidget {
  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  Completer<GoogleMapController> _controller = Completer();

  bool isLocationFetched = false;
  LocationData position;
  CameraPosition initalPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 14.4746,
  );

  Set<Marker> listMarkers = {};

  Location location = new Location();

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
     return Stack(children: [
      GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initalPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: listMarkers,
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
              ),
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                gotoLocation().then((value) => {
                      setState(() {
                        isLocationFetched = true;
                        isLoading = false;
                        listMarkers.add(Marker(
                          markerId: MarkerId("1"),
                          position: value,
                          infoWindow: InfoWindow(title: "My Location"),
                          icon: BitmapDescriptor.defaultMarker,
                        ));
                      })
                    });
              },
              child: Icon(Icons.location_history),
            ),
            Visibility(
                visible: isLocationFetched,
                child: Hero(
                  tag: "hero1",
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: isLocationFetched ? Colors.blue : Colors.grey,
                        shape: CircleBorder(),
                      ),
                      onPressed: () {
                        if (isLocationFetched) {
                          Share.share(
                              'Hello find me here https://www.google.com/maps/@${position.latitude},${position.longitude},15z ',
                              subject: 'I am here buddy');
                        } else {}
                      },
                      child: Icon(Icons.share)),
                ))
          ],
        ),
      ),
      Visibility(
          visible: isLoading,
          child: Center(
            child: CircularProgressIndicator(

            ),
          ))
    ]);
  }

  Future<LatLng> gotoLocation() async {
    GoogleMapController controller = await _controller.future;
    position = await _determinePosition();

    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
         target: LatLng(position.latitude, position.longitude),
         zoom: 19.151926040649414)));

    return LatLng(position.latitude, position.longitude);
  }

  Future<LocationData> _determinePosition() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return Future.error("Location service are disabled");
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        return Future.error("Location denied by user");
      }
    }
    if (_permissionGranted == PermissionStatus.deniedForever) {
      return Future.error(
          "Permisson denied forever goto setting and manually give permission");
    }
    return await location.getLocation();
  }
}
