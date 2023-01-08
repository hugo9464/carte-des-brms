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

  List<Brevet> brevets = [
    Brevet('Paris', 200, 48.8534, 2.3488),
    Brevet('Pau', 400, 43.2983965966848, -0.37161424724523284),
    Brevet('Limoges', 600, 45.837210535461345, 1.2434486386383756),
  ];

  final brevetsFuture =
      supabase.from('brevets').select<List<Map<String, dynamic>>>();

  // mix of [coordinateDebugTileBuilder] and [loadingTimeDebugTileBuilder] from tile_builder.dart
  Widget tileBuilder(BuildContext context, Widget tileWidget, Tile tile) {
    final coords = tile.coords;

    return Container(
      decoration: BoxDecoration(
        border: grid ? Border.all() : null,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          tileWidget,
          if (loadingTime || showCoords)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showCoords)
                  Text(
                    '${coords.x.floor()} : ${coords.y.floor()} : ${coords.z.floor()}',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                if (loadingTime)
                  Text(
                    tile.loaded == null
                        ? 'Loading'
                        // sometimes result is negative which shouldn't happen, abs() corrects it
                        : '${(tile.loaded!.millisecond - tile.loadStarted.millisecond).abs()} ms',
                    style: Theme.of(context).textTheme.headline5,
                  ),
              ],
            ),
        ],
      ),
    );
  }

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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'grid',
            label: Text(
              grid ? 'Hide grid' : 'Show grid',
              textAlign: TextAlign.center,
            ),
            icon: Icon(grid ? Icons.grid_off : Icons.grid_on),
            onPressed: () => setState(() => grid = !grid),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'coords',
            label: Text(
              showCoords ? 'Hide coords' : 'Show coords',
              textAlign: TextAlign.center,
            ),
            icon: Icon(showCoords ? Icons.unarchive : Icons.bug_report),
            onPressed: () => setState(() => showCoords = !showCoords),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'ms',
            label: Text(
              loadingTime ? 'Hide loading time' : 'Show loading time',
              textAlign: TextAlign.center,
            ),
            icon: Icon(loadingTime ? Icons.timer_off : Icons.timer),
            onPressed: () => setState(() => loadingTime = !loadingTime),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'dark-light',
            label: Text(
              darkMode ? 'Light mode' : 'Dark mode',
              textAlign: TextAlign.center,
            ),
            icon: Icon(darkMode ? Icons.brightness_high : Icons.brightness_2),
            onPressed: () => setState(() => darkMode = !darkMode),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'panBuffer',
            label: Text(
              panBuffer == 0 ? 'panBuffer off' : 'panBuffer on',
              textAlign: TextAlign.center,
            ),
            icon: Icon(grid ? Icons.grid_off : Icons.grid_on),
            onPressed: () => setState(() {
              panBuffer = panBuffer == 0 ? 1 : 0;
            }),
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
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: brevetsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final brevets = snapshot.data!;
                    return Text(brevets[0]['city']);
                  },
                ),
                SizedBox(height: 10),
                Row(
                    children:
                        selectedDistances.map((e) => Text('toto')).toList())
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
                    tileBuilder: tileBuilder,
                    tilesContainerBuilder:
                        darkMode ? darkModeTilesContainerBuilder : null,
                    panBuffer: panBuffer,
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
                                    onTap: () {
                                      ScaffoldMessenger.of(ctx)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Tapped on purple FlutterLogo Marker'),
                                      ));
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
