import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Brevet {
  String city;
  int distance;
  double latitude;
  double longitude;
  Brevet(this.city, this.distance, this.latitude, this.longitude);
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

  List<int> selectedDistances = [200, 300, 400, 600, 1000];
  String selectedMarker = '';
  List<Brevet> brevetsToDisplay = [];

  List<Brevet> brevets = [
    Brevet('Paris', 200, 48.8534, 2.3488),
    Brevet('Pau', 400, 43.2983965966848, -0.37161424724523284),
    Brevet('Limoges', 600, 45.837210535461345, 1.2434486386383756),
  ];

  final brevetsFuture =
      supabase.from('brevets').select<List<Map<String, dynamic>>>();

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
            ],
          ),
        ],
      ),
      body: Row(children: [
        Visibility(
          visible: selectedDistances.isNotEmpty,
          child: Expanded(
            flex: 3,
            child: Column(
              children: [
                Visibility(
                    visible: brevetsToDisplay.isNotEmpty,
                    child: Column(
                      children: brevetsToDisplay
                          .map((e) => Card(
                                child: ListTile(
                                  title: Text('${e.distance} km'),
                                  subtitle: Text(e.city),
                                ),
                              ))
                          .toList(),
                    )),
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
                          .where((brevet) =>
                              selectedDistances.contains(brevet['distance']))
                          .map((brevet) => Marker(
                              point: LatLng(
                                  brevet['latitude'], brevet['longitude']),
                              width: 80,
                              height: 80,
                              builder: (ctx) => GestureDetector(
                                    onTap: () => setState(() =>
                                        brevetsToDisplay = brevets
                                            .where((element) =>
                                                element['city'] ==
                                                brevet['city'])
                                            .map((brevet) => Brevet(
                                                brevet['city'],
                                                brevet['distance'],
                                                brevet['latitude'],
                                                brevet['longitude']))
                                            .where((b) => selectedDistances
                                                .contains(b.distance))
                                            .toList()),
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
