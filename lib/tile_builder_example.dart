import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

class Brevet {
  String city;
  int distance;
  double latitude;
  double longitude;
  DateTime date;
  String nomOrganisateur;
  String? mailOrganisateur;
  String? mapLink;
  String? clubWebSite;
  Brevet(
      this.city,
      this.distance,
      this.latitude,
      this.longitude,
      this.date,
      this.nomOrganisateur,
      this.mailOrganisateur,
      this.mapLink,
      this.clubWebSite);
}

_launchURL(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri))
    await launchUrl(uri);
  else
    // can't launch url, there is some error
    throw "Could not launch $url";
}

class TileBuilderPage extends StatefulWidget {
  static const String route = '/tile_builder_example';

  const TileBuilderPage({Key? key}) : super(key: key);

  @override
  _TileBuilderPageState createState() => _TileBuilderPageState();
}

class _TileBuilderPageState extends State<TileBuilderPage>
    with TickerProviderStateMixin {
  bool darkMode = false;
  bool loadingTime = false;
  bool showCoords = false;
  bool grid = false;
  int panBuffer = 0;
  bool _showBeginDateRangePicker = false;
  bool _showEndDateRangePicker = false;

  List<int> selectedDistances = [200, 300, 400, 600, 1000];
  String selectedMarker = '';
  List<Brevet> brevetsToDisplay = [];
  DateTime selectedStartDate = DateTime(2023, 1, 1);
  DateTime selectedEndDate = DateTime(2023, 12, 31);
  String hoveredMarker = '';
  double mapZoom = 6;

  final brevetsFuture =
      supabase.from('brevets').select<List<Map<String, dynamic>>>();

  final DateRangePickerController _controller = DateRangePickerController();
  MapController _mapController = MapController();

  FloatingActionButton buildDistanceFilter(int distance) {
    return FloatingActionButton.extended(
      backgroundColor:
          selectedDistances.contains(distance) ? Colors.lightGreen : Colors.red,
      heroTag: distance,
      label: Text(
        distance.toString(),
        textAlign: TextAlign.center,
      ),
      onPressed: () {
        setState(() {
          selectedDistances.contains(distance)
              ? selectedDistances.remove(distance)
              : selectedDistances.add(distance);
        });
      },
    );
  }

  Column _getGettingStartedDatePicker(bool isStart) {
    return Column(
      children: [
        const Text('Afficher les brevets avant le :'),
        SfDateRangePicker(
          showNavigationArrow: true,
          minDate: DateTime(2023, 1, 1),
          maxDate: DateTime(2023, 12, 31),
          initialDisplayDate: isStart ? selectedStartDate : selectedEndDate,
          initialSelectedDate: isStart ? selectedStartDate : selectedEndDate,
          selectionMode: DateRangePickerSelectionMode.single,
          headerStyle:
              const DateRangePickerHeaderStyle(textAlign: TextAlign.center),
          monthViewSettings: const DateRangePickerMonthViewSettings(
              firstDayOfWeek: 1,
              showTrailingAndLeadingDates: true,
              enableSwipeSelection: false),
          onSelectionChanged: (dateRangePickerSelectionChangedArgs) => {
            setState(() {
              isStart
                  ? (selectedStartDate =
                      dateRangePickerSelectionChangedArgs.value)
                  : (selectedEndDate =
                      dateRangePickerSelectionChangedArgs.value);
              isStart
                  ? (_showBeginDateRangePicker = !_showBeginDateRangePicker)
                  : (_showEndDateRangePicker = !_showEndDateRangePicker);
            })
          },
        ),
        const SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
                onPressed: () => {
                      setState(() {
                        isStart
                            ? (_showBeginDateRangePicker =
                                !_showBeginDateRangePicker)
                            : (_showEndDateRangePicker =
                                !_showEndDateRangePicker);

                        isStart
                            ? (selectedStartDate = DateTime(2023, 1, 1))
                            : (selectedEndDate = DateTime(2023, 12, 31));
                      })
                    },
                child: const Text('EFFACER')),
            TextButton(
                onPressed: () => {
                      setState(() {
                        isStart
                            ? (_showBeginDateRangePicker =
                                !_showBeginDateRangePicker)
                            : (_showEndDateRangePicker =
                                !_showEndDateRangePicker);
                      })
                    },
                child: const Text('OK')),
          ],
        ),
      ],
    );
  }

  FloatingActionButton buildDatePickerButton(String label) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.lightBlue,
      label: Text(
        label,
        textAlign: TextAlign.center,
      ),
      onPressed: () {
        setState(() {
          _showBeginDateRangePicker = !_showBeginDateRangePicker;
        });
      },
    );
  }

  @override
  void initState() {
    _controller.displayDate = DateTime.now();
    _controller.selectedDate = DateTime.now();
    _controller.view = DateRangePickerView.month;

    super.initState();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final latTween = Tween<double>(
        begin: _mapController.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(width: 50),
              buildDistanceFilter(200),
              const SizedBox(width: 8),
              buildDistanceFilter(300),
              const SizedBox(width: 8),
              buildDistanceFilter(400),
              const SizedBox(width: 8),
              buildDistanceFilter(600),
              const SizedBox(width: 8),
              buildDistanceFilter(1000),
              const SizedBox(width: 70),
              FloatingActionButton.extended(
                backgroundColor: Colors.lightBlue,
                label: Text(
                  'Du ' + DateFormat('dd/MM/yyyy').format(selectedStartDate),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  setState(() {
                    _showBeginDateRangePicker = !_showBeginDateRangePicker;
                  });
                },
              ),
              const SizedBox(width: 8),
              FloatingActionButton.extended(
                backgroundColor: Colors.lightBlue,
                label: Text(
                  'Au ' + DateFormat('dd/MM/yyyy').format(selectedEndDate),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  setState(() {
                    _showEndDateRangePicker = !_showEndDateRangePicker;
                  });
                },
              ),
              const SizedBox(width: 50),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Visibility(
                visible: _showBeginDateRangePicker,
                child: Container(
                  height: 380,
                  width: 300,
                  child: Card(
                      elevation: 10,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                        child: _getGettingStartedDatePicker(true),
                      )),
                ),
              ),
              Visibility(
                visible: _showEndDateRangePicker,
                child: Container(
                  height: 350,
                  width: 300,
                  child: Card(
                      elevation: 10,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                        child: _getGettingStartedDatePicker(false),
                      )),
                ),
              ),
              const SizedBox(width: 50),
            ],
          ),
        ],
      ),
      body: Row(children: [
        Visibility(
          visible: selectedMarker.isNotEmpty,
          child: Expanded(
            flex: 3,
            child: Column(
              children: [
                const SizedBox(
                  height: 50,
                ),
                if (selectedMarker.isNotEmpty)
                  Container(
                    width: 200,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_city,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedMarker,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: SizedBox(
                    height: 500,
                    child: ListView(
                      children: brevetsToDisplay
                          .map((brevet) => Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.white,
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 10.0,
                                      left: 6.0,
                                      right: 6.0,
                                      bottom: 10.0,
                                    ),
                                    child: ExpansionTile(
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.straighten,
                                              color: Colors.lightBlue),
                                          const SizedBox(width: 5),
                                          Text(brevet.distance.toString() +
                                              ' KM'),
                                          const SizedBox(width: 40),
                                          const Icon(Icons.calendar_month,
                                              color: Colors.lightBlue),
                                          const SizedBox(width: 5),
                                          Text(DateFormat('dd/MM/yyyy')
                                              .format(brevet.date)),
                                        ],
                                      ),
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                        Icons.perm_identity,
                                                        color:
                                                            Colors.lightBlue),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                      brevet.nomOrganisateur,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                        Icons.mail_outline,
                                                        color:
                                                            Colors.lightBlue),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    SelectableText(
                                                      brevet.mailOrganisateur!,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                if (brevet.clubWebSite != null)
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        _launchURL(brevet
                                                            .clubWebSite!);
                                                      },
                                                      child: Text(
                                                          'Site internet')),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                if (brevet.mapLink != null)
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        _launchURL(
                                                            brevet.mapLink!);
                                                      },
                                                      child:
                                                          Text('Itinéraire')),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    )),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: brevetsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final brevets = snapshot.data!;

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: LatLng(46.227638, 2.213749),
                  zoom: 6,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=c039ca3093f842ac8ffd0039ad22226c',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                      markers: brevets
                          .map((e) => Brevet(
                              e['city'],
                              e['distance'],
                              e['latitude'],
                              e['longitude'],
                              DateFormat('d/M/y').parse(e['date']),
                              e['nomorganisateur'],
                              e['mailorganisateur'],
                              e['maplink'],
                              e['clubwebsite']))
                          .where((brevet) =>
                              selectedDistances.contains(brevet.distance))
                          .where((brevet) =>
                              brevet.date.isAfter(selectedStartDate))
                          .where(
                              (brevet) => brevet.date.isBefore(selectedEndDate))
                          .map((brevet) => Marker(
                              point: LatLng(brevet.latitude, brevet.longitude),
                              width: 15,
                              height: 15,
                              builder: (ctx) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      brevetsToDisplay = brevets
                                          .where((element) =>
                                              element['city'] == brevet.city)
                                          .map((brevet) => Brevet(
                                              brevet['city'],
                                              brevet['distance'],
                                              brevet['latitude'],
                                              brevet['longitude'],
                                              DateFormat('d/M/y')
                                                  .parse(brevet['date']),
                                              brevet['nomorganisateur'],
                                              brevet['mailorganisateur'],
                                              brevet['maplink'],
                                              brevet['clubwebsite']))
                                          .toList();
                                      selectedMarker = brevet.city;
                                      _animatedMapMove(
                                          LatLng(brevet.latitude,
                                              brevet.longitude),
                                          10);
                                    });
                                    _mapController.move(
                                        LatLng(
                                            brevet.latitude, brevet.longitude),
                                        10);
                                  },
                                  child: MouseRegion(
                                    onEnter: (event) => {
                                      setState(
                                        () => hoveredMarker = brevet.city,
                                      )
                                    },
                                    onExit: (event) => {
                                      setState(
                                        () => hoveredMarker = '',
                                      )
                                    },
                                    child: Icon(
                                      Icons.circle,
                                      color: brevet.city == selectedMarker
                                          ? Colors.blue
                                          : Colors.red,
                                      size: (brevet.city == hoveredMarker) ||
                                              (brevet.city == selectedMarker)
                                          ? 20
                                          : 12,
                                    ),
                                  ))))
                          .toList()),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
