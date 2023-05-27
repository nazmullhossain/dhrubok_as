import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    _determinePosition();
    super.initState();
  }

  Position? position;

  Map<String, dynamic>? weatherMap;
  Map<String, dynamic>? forecastMap;

  _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    position = await Geolocator.getCurrentPosition();

    fetchWeatherData();
  }

  fetchWeatherData() async {
    String weatherAPI =
        "https://api.openweathermap.org/data/2.5/weather?lat=${position!.latitude}&lon=${position!.longitude}&appid=c05bc98192aa48b04f9710b62b4777f3";

    String forecastAPI =
        "https://api.openweathermap.org/data/2.5/forecast?lat=${position!.latitude}&lon=${position!.longitude}&appid=c05bc98192aa48b04f9710b62b4777f3";

    var weatherResponse = await http.get(Uri.parse(weatherAPI));
    var forecastResponse = await http.get(Uri.parse(forecastAPI));
    print("wetherResponse${weatherResponse.body}");
    print("forecastResponse${forecastResponse.body}");

    setState(() {
      weatherMap = Map<String, dynamic>.from(jsonDecode(weatherResponse.body));
      forecastMap =
      Map<String, dynamic>.from(jsonDecode(forecastResponse.body));
    });

    ///print(weatherResponse.body.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (weatherMap == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      var celsious = weatherMap!["main"]["temp"] - 273.15;
      var tempFeels = weatherMap!["main"]["feels_like"] - 273.15;

      return SafeArea(
        child: Scaffold(
          backgroundColor: Color.fromARGB(255, 173, 203, 255),
          body: weatherMap == null
              ? Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  title: Text('${weatherMap!['name']}'),
                  subtitle: Text(
                      '${Jiffy(DateTime.now()).format('MMMM dd yyy, h:mm a')}'),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '${celsious.toStringAsFixed(1)}°C',
                            style: TextStyle(fontSize: 45),
                          ),
                          Text('${weatherMap!['weather'][0]['main']}'),
                          Row(
                            children: [
                              Text(
                                  '🌡 Feels like ${tempFeels.toStringAsFixed(0)}°C |'),
                              Text(
                                  "💨 Wind ${weatherMap!['wind']['speed']} KM/H")
                            ],
                          )
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: 50,
                      backgroundImage: NetworkImage(
                          'https://openweathermap.org/img/wn/${weatherMap!['weather'][0]['icon']}@2x.png'),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text("DETAILS",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),
                Expanded(
                  flex: 1,
                  child: GridView.count(crossAxisCount: 3, children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          tileColor: Colors.transparent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          title: Text(
                              "${weatherMap!['main']['humidity']}%",
                              style:
                              TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Humidity"),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          tileColor: Colors.transparent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          title: Text(
                              '${Jiffy(DateTime.fromMillisecondsSinceEpoch(weatherMap!['sys']['sunrise'] * 1000)).format('h:mm a')}',
                              style:
                              TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Sunrise"),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          tileColor: Colors.transparent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          title: Text(
                              '${Jiffy(DateTime.fromMillisecondsSinceEpoch(weatherMap!['sys']['sunset'] * 1000)).format('h:mm a')}',
                              style:
                              TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Sunset"),
                        ),
                      ),
                    )
                  ]),
                ),
                const Align(
                    alignment: Alignment.topLeft,
                    child: Text("Forecast",
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: forecastMap!.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          height: 50,
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(20.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${Jiffy("${forecastMap!["list"][index]["dt_txt"]}").format("EEE, h:mm a")}",
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      Text(
                                          "${(forecastMap!['list'][index]['main']['temp'] - 273.15).toStringAsFixed(1)}"),
                                      Image.network(
                                          'https://openweathermap.org/img/wn/${forecastMap!['list'][index]['weather'][0]['icon']}@2x.png'),
                                      Text(
                                          "${forecastMap!['list'][index]['weather'][0]['main']}"),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ]),
                        );
                      },
                    ))
              ],
            ),
          ),
        ),
      );
    }
  }
}