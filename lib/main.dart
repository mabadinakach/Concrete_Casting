import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:neumorphic/neumorphic.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

var apiKey = "2627cfdef0f5433d976172353201310";
String temp = "temp_c";
String avgTemp = "avgtemp_c";
String maxTemp = "maxtemp_c";
String minTemp = "mintemp_c";

Color colorText = Color.fromRGBO(114, 138, 183, 1);
Color colorBackground = Color.fromRGBO(240, 240, 243, 1);
Color detailGreen = Color.fromRGBO(131, 219, 214, 1);
Color detailRed = Color.fromRGBO(251, 117, 117, 1);

void main() {
  runApp(MyApp());
}

class PlaceholderWidget extends StatelessWidget {
  final Color color;

  PlaceholderWidget(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.cyan,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeTabBar(),
    );
  }
}

class HomeTabBar extends StatefulWidget {
  HomeTabBar({Key key}) : super(key: key);

  @override
  _HomeTabBarState createState() => _HomeTabBarState();
}

class _HomeTabBarState extends State<HomeTabBar> {

  // TabBar View

  int _currentIndex = 0;

  final List<Widget> _children = [
    Home(),
    Info(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped, // this will be set when a new tab is tapped
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.info),
            label: 'Info',
          ),
        ],
      ),
      body: _children[_currentIndex],
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  // Home View

  final GeolocatorPlatform geolocator = GeolocatorPlatform.instance;
  Position _currentPosition;

  bool permissionDenied = false;
  bool web = false;

  var lat = "";
  var long = "";

  Future checkPermission() async {
    // Function check if user has granted location permision
    if (kIsWeb) {
      print("WEEEB");
      // running on the web!
      http.get("https://geolocation-db.com/json/").then((response) {
        var json1 = json.decode(response.body);
        print(json1["latitude"]);

        setState(() {
          web = true;
          lat = json1["latitude"].toString();
          long = json1["longitude"].toString();
        });
        getWeather();
        

      });
    } else {
      var status = await Permission.location.status;
      print(status);
      // NOT running on the web! You can check for additional platforms here.
      if (await Permission.location.isDenied ||
        await Permission.location.isRestricted) {
        print("turned truee");
        setState(() {
          permissionDenied = true;
        });
        getWeather();
      }
    }

  }

  List<String> text = [];
  var data = null;
  int todayGoodCount = 0;

  _getCurrentLocation() {
    // Function to display the dialog to enable location permission to the app.

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        getWeather();
      });
    }).catchError((e) {
      print(e);
    });
  }

  int calculatePercentage(int n) {
    // Function to calculate effieciency percentage based on the temperature
    int x = 15 - n;
    int percentage = x.abs() * 10;
    return (100 - percentage);
  }

  Future getWeather() async {
    // Function to obtain weather data from API
    var url = permissionDenied
        ? "https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=37.773972,-122.431297&days=5" :
        web ? "https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=${lat},${long}&days=5" : "https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=${_currentPosition.latitude},${_currentPosition.longitude}&days=5";
    print(url);
    http.get(url).then((response) {
      var json1 = json.decode(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        data = json1;
        outer:
        for (var i = 0; i < json1["forecast"]["forecastday"].length; i++) {
          setState(() {
            text.add(json1["forecast"]["forecastday"][i]["date"]);
          });
          todayGoodCount = 0;
          for (var hour = 0;
              hour < json1["forecast"]["forecastday"][i]["hour"].length;
              hour++) {
            if (json1["forecast"]["forecastday"][i]["hour"][hour]["is_day"] ==
                    1 &&
                int.parse(json1["forecast"]["forecastday"][i]["hour"][hour]
                        ["chance_of_rain"]) <
                    30 &&
                json1["forecast"]["forecastday"][i]["hour"][hour]
                        ["will_it_rain"] ==
                    0 &&
                data["forecast"]["forecastday"][i]["hour"][hour][temp] >= 5 &&
                data["forecast"]["forecastday"][i]["hour"][hour][temp] <= 25) {
              todayGoodCount++;

              data["forecast"]["forecastday"][i]["count"] = todayGoodCount;
              data["forecast"]["forecastday"][i]["hour"][hour]["good"] = true;
              data["forecast"]["forecastday"][i]["hour"][hour]["efficiency"] =
                  calculatePercentage(data["forecast"]["forecastday"][i]["hour"]
                          [hour][temp]
                      .toInt());
              continue outer;
            }
          }
        }
        //TEST DATA (used to test edge cases)

        // data["forecast"]["forecastday"][0]["count"] = null;
        // data["forecast"]["forecastday"][0]["hour"][8]["good"] = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkPermission();
    if (permissionDenied == false) _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NeuAppBar(
        title: Text("Concrete Casting", style: TextStyle(fontSize: 20)),
      ),
      body: ListView.builder(
        itemCount: 1,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: <Widget>[
              data != null
                  ? Column(
                      children: [
                        permissionDenied
                            ? Text(
                                "Location not found, using San Francisco as location.\nPlease grant location permission",
                                style: TextStyle(fontWeight: FontWeight.bold))
                            : SizedBox(),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 30,
                                child: InkWell(
                                  child: Text(
                                    "F",
                                    style: TextStyle(
                                        fontSize: 25,
                                        color: temp == "temp_f"
                                            ? Colors.indigo
                                            : Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      temp = "temp_f";
                                      avgTemp = "avgtemp_f";
                                      maxTemp = "maxtemp_f";
                                      minTemp = "mintemp_f";
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                width: 30,
                                child: InkWell(
                                  child: Text(
                                    "C",
                                    style: TextStyle(
                                        fontSize: 25,
                                        color: temp == "temp_c"
                                            ? Colors.indigo
                                            : Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      temp = "temp_c";
                                      avgTemp = "avgtemp_c";
                                      maxTemp = "maxtemp_c";
                                      minTemp = "mintemp_c";
                                    });
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: NeumorphicContainer(
                                  bevel: 5,
                                  color: colorBackground,
                                  child: Text("Today",
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: colorText,
                                          fontWeight: FontWeight.bold))),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        new DayDetail(
                                          data: data["forecast"]["forecastday"]
                                              [0],
                                          today: true,
                                          weather:
                                              data["current"][temp].toString(),
                                        )));
                          },
                          child: NeumorphicContainer(
                            color: colorBackground,
                            bevel: 3,
                            child: Stack(children: <Widget>[
                              Positioned(
                                  child: Container(
                                width: MediaQuery.of(context).size.width - 200,
                                height: 170,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20))),
                              )),
                              Positioned.fill(
                                  child: Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Text(
                                    DateFormat('EEEE').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            data["forecast"]["forecastday"]
                                              [0]["date_epoch"] *
                                                1000)),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 30, color: colorText),
                                  ),
                                ),
                              )),
                              // Positioned.fill(
                              //   child: Align(
                              //     alignment: Alignment.bottomCenter,
                              //     child: Padding(
                              //       padding: const EdgeInsets.fromLTRB(0, 30, 0, 30),
                              //       child: Image.network("http:${data["forecast"]["forecastday"][0]["day"]["condition"]["icon"]}")
                              //     ),
                              //   )
                              // ),
                              Positioned.fill(
                                  child: Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${data["current"][temp].toString()}º",
                                    style: TextStyle(
                                        fontSize: 70,
                                        color: colorText,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )),
                              data["forecast"]["forecastday"][0]["count"] ==
                                      null
                                  ? SizedBox()
                                  : Positioned(
                                      top: 0,
                                      left: 5,
                                      child: Opacity(
                                          opacity: 1,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: colorText,
                                              shape: BoxShape.circle,
                                            ),
                                          ))),
                              data["forecast"]["forecastday"][0]["count"] ==
                                      null
                                  ? SizedBox()
                                  : Positioned(
                                      top: 0,
                                      left: 5,
                                      child: Container(
                                          width: 30,
                                          height: 30,
                                          child: Center(
                                              child: Text(
                                            "${data["forecast"]["forecastday"][0]["count"].toString()}",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          )))),
                            ]),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(),

              SizedBox(height: 10),
              // if (permissionDenied == true)
              //   Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Text("Location permission denied, please allow it to retrieve weather", style: TextStyle(
              //       fontSize: 30,

              //     ),textAlign: TextAlign.center,),
              //   )
              //  else
              if (data == null /*&& permissionDenied == false*/)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: NeumorphicContainer(
                          bevel: 5,
                          color: colorBackground,
                          child: Text("Next Days",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: colorText,
                                  fontWeight: FontWeight.bold))),
                    ),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: <Widget>[
                          for (var i = 1;
                              i < data["forecast"]["forecastday"].length;
                              i++)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              new DayDetail(
                                                data: data["forecast"]
                                                    ["forecastday"][i],
                                                today: false,
                                                weather: "",
                                              )));
                                },
                                child: NeumorphicContainer(
                                  color: Color.fromRGBO(240, 240, 243, 1),
                                  bevel: 3,
                                  child: Stack(children: <Widget>[
                                    Positioned(
                                        child: Container(
                                      width: MediaQuery.of(context).size.width -
                                          200,
                                      height: 250,
                                      decoration: BoxDecoration(
                                          //color: Colors.blue,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20))),
                                    )),
                                    Positioned.fill(
                                        child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 0, 0, 20),
                                          child: Image.network(
                                              "http:${data["forecast"]["forecastday"][i]["day"]["condition"]["icon"]}")
                                          // child: Text(
                                          //   "${data["forecast"]["forecastday"][i]["day"]["condition"]["text"]}",
                                          //   style: TextStyle(
                                          //     fontSize: 20,
                                          //     color: Colors.white
                                          //   ),
                                          //   textAlign: TextAlign.center,
                                          // ),
                                          ),
                                    )),
                                    Positioned.fill(
                                        child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Text(
                                          DateFormat('EEE').format(DateTime
                                              .fromMillisecondsSinceEpoch(
                                                  data["forecast"]
                                                              ["forecastday"][i]
                                                          ["date_epoch"] *
                                                      1000)),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 30, color: colorText),
                                        ),
                                      ),
                                    )),
                                    Positioned.fill(
                                        child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "${data["forecast"]["forecastday"][i]["day"][avgTemp].toString()}º",
                                        style: TextStyle(
                                            fontSize: 70,
                                            color: Color.fromRGBO(
                                                114, 138, 183, 1),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )),
                                    data["forecast"]["forecastday"][i]
                                                ["count"] ==
                                            null
                                        ? SizedBox()
                                        : Positioned(
                                            top: 5,
                                            left: 10,
                                            child: Opacity(
                                                opacity: 1,
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: colorText,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ))),
                                    data["forecast"]["forecastday"][i]
                                                ["count"] ==
                                            null
                                        ? SizedBox()
                                        : Positioned(
                                            top: 5,
                                            left: 10,
                                            child: Container(
                                                width: 30,
                                                height: 30,
                                                child: Center(
                                                    child: Text(
                                                  "${data["forecast"]["forecastday"][i]["count"].toString()}",
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white),
                                                )))),
                                  ]),
                                ),
                              ),
                            ),
                        ])),
                  ],
                )
            ]),
          );
        },
      ),
    );
  }
}

class DayDetail extends StatefulWidget {
  DayDetail({Key key, this.data, this.today, this.weather}) : super(key: key);

  final Map<String, dynamic> data;
  final bool today;
  final String weather;

  @override
  _DayDetailState createState() => _DayDetailState();
}

class _DayDetailState extends State<DayDetail> {

  // Day Detail View

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            DateFormat('MMMMd').format(DateTime.fromMillisecondsSinceEpoch(
                widget.data["date_epoch"] * 1000,
                isUtc: false)),
          ),
          backgroundColor: Colors.white,
        ),
        body: Container(
          color: widget.data["count"] != null ? detailGreen : detailRed,
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "${DateFormat('EEEE').format(DateTime.fromMillisecondsSinceEpoch(widget.data["date_epoch"] * 1000, isUtc: false))}",
                        style: TextStyle(fontSize: 30, color: Colors.white)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                widget.today
                    ? "${widget.weather}º"
                    : "${widget.data["day"][avgTemp].toString()}º",
                style: TextStyle(
                    fontSize: 130,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Opacity(
                      opacity: 0.6,
                      child: Text("${widget.data["day"][minTemp].toString()}º",
                          style: TextStyle(fontSize: 40, color: Colors.white)),
                    ),
                    Spacer(),
                    Text("${widget.data["day"][maxTemp].toString()}º",
                        style: TextStyle(fontSize: 40, color: Colors.white)),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              widget.data["count"] == null
                  ? Text(
                      "Today is NOT a good day for casting",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    )
                  : SizedBox(),
              for (var i = 0; i < widget.data["hour"].length; i++)
                widget.data["hour"][i]["good"] == true
                    ? Text(
                        "Recommended time to start casting: ${widget.data["hour"][i]["time"].substring(11)}\n\n Efficiency in casting: %${widget.data["hour"][i]["efficiency"].toString()}",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      )
                    : SizedBox(),
              //Image.network("http:${widget.data["day"]["condition"]["icon"]}"),
              Spacer(),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SafeArea(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: <Widget>[
                          for (var i = 0; i < widget.data["hour"].length; i++)
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    SlideRightRoute(
                                        page: DetailHour(
                                            data: widget.data["hour"][i])));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Stack(children: [
                                  Positioned(
                                      child: Container(
                                    width:
                                        MediaQuery.of(context).size.width - 300,
                                    height: 120,
                                    decoration: BoxDecoration(
                                        color: widget.data["hour"][i]["good"] ==
                                                true
                                            ? detailGreen
                                            : widget.data["hour"][i]
                                                        ["time_epoch"] ==
                                                    DateTime.now()
                                                ? detailRed
                                                : colorText,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                  )),
                                  Positioned.fill(
                                      child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        widget.data["hour"][i]["time"]
                                            .substring(11),
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                      ),
                                    ),
                                  )),
                                  Positioned.fill(
                                      child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${widget.data["hour"][i][temp].toString()}º",
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.white),
                                    ),
                                  )),
                                  Positioned.fill(
                                      child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Image.network(
                                            "http:${widget.data["hour"][i]["condition"]["icon"]}",
                                            height: 40,
                                          ))),
                                ]),
                              ),
                            )
                        ])),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}

class DetailHour extends StatefulWidget {
  DetailHour({Key key, this.data}) : super(key: key);

  final Map<String, dynamic> data;
  @override
  _DetailHourState createState() => _DetailHourState();
}

class _DetailHourState extends State<DetailHour> {

  // Detail Hour View

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.data["time"].substring(11)),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView.builder(
        itemCount: 1,
        itemBuilder: (BuildContext context, int index) {
          return Table(
            border: TableBorder(
                horizontalInside: BorderSide(
                    width: 1, color: colorText, style: BorderStyle.solid)),
            //columnWidths: {0: FractionColumnWidth(.4), 1: FractionColumnWidth(.2), 2: FractionColumnWidth(.4)},
            children: [
              TableRow(children: [
                Container(
                  height: 50,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Temperature",
                            style: TextStyle(
                              fontSize: 20,
                            )),
                        Text("${widget.data[temp].toString()}º",
                            style: TextStyle(
                              fontSize: 20,
                            ))
                      ]),
                )
              ]),
              TableRow(children: [
                Container(
                  height: 50,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Wind",
                            style: TextStyle(
                              fontSize: 20,
                            )),
                        Text("${widget.data["wind_mph"].toString()} MPH",
                            style: TextStyle(
                              fontSize: 20,
                            ))
                      ]),
                )
              ]),
              TableRow(children: [
                Container(
                  height: 50,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Wind Degree",
                            style: TextStyle(
                              fontSize: 20,
                            )),
                        Text("${widget.data["wind_degree"].toString()}º",
                            style: TextStyle(
                              fontSize: 20,
                            ))
                      ]),
                )
              ]),
              TableRow(children: [
                Container(
                  height: 50,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Wind Direction",
                            style: TextStyle(
                              fontSize: 20,
                            )),
                        Text("${widget.data["wind_dir"].toString()}",
                            style: TextStyle(
                              fontSize: 20,
                            ))
                      ]),
                )
              ]),
              TableRow(children: [
                Container(
                  height: 50,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Humidity",
                            style: TextStyle(
                              fontSize: 20,
                            )),
                        Text("%${widget.data["humidity"].toString()}",
                            style: TextStyle(
                              fontSize: 20,
                            ))
                      ]),
                )
              ]),
              TableRow(children: [
                Container(
                  height: 50,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Chance of Rain",
                            style: TextStyle(
                              fontSize: 20,
                            )),
                        Text("%${widget.data["chance_of_rain"].toString()}",
                            style: TextStyle(
                              fontSize: 20,
                            ))
                      ]),
                )
              ]),
            ],
          );
        },
      ),
    );
  }
}

class Info extends StatefulWidget {
  Info({Key key}) : super(key: key);

  @override
  _InfoState createState() => _InfoState();
}

class _InfoState extends State<Info> {

  // Info View

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Information"),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: 1,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Text(
                    "The ACI defines cold weather when the average daily temperature for more than three consecutive days is less than 5° C and if the temperature rises above 10° C for more than half a day it is no longer considered cold weather.\n\nAci defines hot weather when any combination of high air temperature, low relative humidity, and ambient velocity affect the quality of fresh and hardened ants.",
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 20),
                Text(
                  "Preparation of Mixture",
                  style: TextStyle(fontSize: 30),
                ),
                Divider(),
                Text(
                  "The ideal temperature for the placing of concrete is 15º C, which is imposible to optain in warm weather. There should be the best effort done to get the concrete below 30º C by using ice",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Formula to determine how much ice should be used in concrete.",
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 20),
                ),
                Image.asset("assets/formula.png"),
                SizedBox(height: 10),
                Text(
                  "Placing of Concrete",
                  style: TextStyle(fontSize: 30),
                ),
                Divider(),
                Text(
                  "To mantain the quality of the concrete during the process of casting the following is recomended:\n",
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  "· The terrain must be wet\n\n· If there is a delay in the casting apply mist type irrigation\n\n· If cold joints have formed it is recommended to moisten with cement grout before placing the fresh concrete\n\n· The cracks should be filled with a cement mortar grout or some epoxy glue\n\n· In the case of massive castings and concrete with a high cement content, the effects described above are magnified so additional precautions should be taken\n\n· It will be preferable to place the concrete in hours of lower temperature and even do it at night",
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  "Dosing of Concrete",
                  style: TextStyle(fontSize: 30),
                ),
                Divider(),
                Text(
                  "When temperatures lower than the limit indicated (5º C) are estimated, it is convenient to have alternative design mixtures so that the work can be continued in normal ways",
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  "Design of Alternative Mixtures",
                  style: TextStyle(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
                Divider(),
                Text(
                  "Any of the following procedures can be used:\n",
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  "· Bigger dose of cement\n\n· More resistant cement\n\n· Additives to reduce water/cement ratio",
                  style: TextStyle(fontSize: 20),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  SlideRightRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
}

// From https://medium.com/flutter-community/neumorphic-designs-in-flutter-eab9a4de2059

class NeumorphicContainer extends StatefulWidget {
  final Widget child;
  final double bevel;
  final Offset blurOffset;
  final Color color;

  NeumorphicContainer({
    Key key,
    this.child,
    this.bevel = 10.0,
    this.color,
  })  : this.blurOffset = Offset(bevel / 2, bevel / 2),
        super(key: key);

  @override
  _NeumorphicContainerState createState() => _NeumorphicContainerState();
}

class _NeumorphicContainerState extends State<NeumorphicContainer> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = this.widget.color ?? Theme.of(context).backgroundColor;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.bevel * 10),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _isPressed ? color : color.mix(Colors.black, .1),
                _isPressed ? color.mix(Colors.black, .05) : color,
                _isPressed ? color.mix(Colors.black, .05) : color,
                color.mix(Colors.white, _isPressed ? .2 : .5),
              ],
              stops: [
                0.0,
                .3,
                .6,
                1.0,
              ]),
          boxShadow: _isPressed
              ? null
              : [
                  BoxShadow(
                    blurRadius: widget.bevel,
                    offset: -widget.blurOffset,
                    color: color.mix(Colors.white, .6),
                  ),
                  BoxShadow(
                    blurRadius: widget.bevel,
                    offset: widget.blurOffset,
                    color: color.mix(Colors.black, .3),
                  )
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

extension ColorUtils on Color {
  Color mix(Color another, double amount) {
    return Color.lerp(this, another, amount);
  }
}
