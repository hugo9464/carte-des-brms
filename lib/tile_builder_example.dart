import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

final supabase = Supabase.instance.client;

class Brevet {
  String city;
  int distance;
  double latitude;
  double longitude;
  DateTime date;
  Brevet(this.city, this.distance, this.latitude, this.longitude, this.date);
}

class TileBuilderPage extends StatefulWidget {
  static const String route = '/tile_builder_example';

  const TileBuilderPage({Key? key}) : super(key: key);

  @override
  _TileBuilderPageState createState() => _TileBuilderPageState();
}

class _TileBuilderPageState extends State<TileBuilderPage> {
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

  final brevetsFuture =
      supabase.from('brevets').select<List<Map<String, dynamic>>>();

  final DateRangePickerController _controller = DateRangePickerController();

  FloatingActionButton buildDistanceFilter(int distance) {
    return FloatingActionButton.extended(
      backgroundColor:
          selectedDistances.contains(distance) ? Colors.lightBlue : Colors.red,
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
        SfDateRangePicker(
          showNavigationArrow: true,
          minDate: DateTime(2023, 1, 1),
          maxDate: DateTime(2023, 12, 31),
          initialDisplayDate: isStart ? selectedStartDate : selectedEndDate,
          initialSelectedDate: isStart ? selectedStartDate : selectedEndDate,
          selectionMode: DateRangePickerSelectionMode.single,
          headerStyle: DateRangePickerHeaderStyle(textAlign: TextAlign.center),
          monthViewSettings: DateRangePickerMonthViewSettings(
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
        TextButton(
            onPressed: () => {
                  setState(() {
                    isStart
                        ? (_showBeginDateRangePicker =
                            !_showBeginDateRangePicker)
                        : (_showEndDateRangePicker = !_showEndDateRangePicker);
                  })
                },
            child: Text('FERMER'))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                  height: 350,
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
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Text(selectedMarker),
            ],
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
                              DateFormat('d/M/y').parse(e['date'])))
                          .where((brevet) =>
                              selectedDistances.contains(brevet.distance))
                          .where((brevet) =>
                              brevet.date.isAfter(selectedStartDate))
                          .where(
                              (brevet) => brevet.date.isBefore(selectedEndDate))
                          .map((brevet) => Marker(
                              point: LatLng(brevet.latitude, brevet.longitude),
                              width: 80,
                              height: 80,
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
                                                    .parse(brevet['date'])))
                                            .toList();
                                        selectedMarker = brevet.city;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.circle,
                                      color: Colors.red,
                                      size: 12,
                                    ),
                                  )))
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
