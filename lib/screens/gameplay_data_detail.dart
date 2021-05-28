import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';
import 'package:csv/csv.dart';

class GameplayDataDetailPage extends StatefulWidget {
  final String title;
  final GameplayData gameplayData;

  GameplayDataDetailPage({Key key, this.title, this.gameplayData})
      : super(key: key);

  @override
  _GameplayDataDetailPageState createState() => _GameplayDataDetailPageState();
}

class _GameplayDataDetailPageState extends State<GameplayDataDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    GameplayData gameplayData = widget.gameplayData;



    return Scaffold(
        appBar: AppBar(
          title: Text("Detailed Data Page"),
        ),
        body: Column(children: <Widget>[
          Container(height: 300,
              child:Padding(
                  padding:const EdgeInsets.only(left:20.0,right:20.0,bottom:20.0),
                  child:FutureBuilder<String>(future:getJSONfile(),
                      builder: (context, AsyncSnapshot<String> jsonString) {
                        if(jsonString.hasData) {
                          final decodedJSON = json.decode(jsonString.data);
                          List<Map<String,dynamic>> data = [];
                          String whatToCall = "rawValue";
                          int initialTimestamp = decodedJSON["processedData"][0]["timestamp"];
                          for(int i = 0; i < decodedJSON["processedData"].length; i+=4) {
                            if (decodedJSON["processedData"][i].containsKey("voltage")) {
                              data.add(decodedJSON["processedData"][i]);
                              whatToCall="voltage";
                            } else {
                              data.add(decodedJSON["processedData"][i]);
                            }
                          }
                          final graphData = [
                            new charts.Series<Map<String,dynamic>, int>(
                              id: 'Voltage',
                              colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
                              domainFn: (Map<String,dynamic> voltage, _) => voltage["timestamp"]-initialTimestamp,
                              measureFn: (Map<String,dynamic> voltage, _) => voltage[whatToCall],
                              data: data
                            )
                          ];
                          return charts.LineChart(graphData,animate:false,
                          behaviors:[
                            new charts.ChartTitle("Gameplay Data Recording",
                            behaviorPosition:charts.BehaviorPosition.top,
                            innerPadding:10),
                            new charts.PanAndZoomBehavior()
                          ],
                          domainAxis:new charts.NumericAxisSpec(viewport: new charts.NumericExtents(0.0,1000.0),
                              showAxisLine: true,
                              renderSpec: new charts.NoneRenderSpec()));
                        } else {
                          return CircularProgressIndicator();
                        }
                      }
                  )
              )
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Start Time:',
                              style: const TextStyle(fontSize: 20)),
                          Text(
                              '${DateTimeFromTimeSinceEpoch(gameplayData.startTime)}',
                              style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('End Time:',
                                style: const TextStyle(fontSize: 20)),
                            Text(
                                '${DateTimeFromTimeSinceEpoch(gameplayData.endTime)}',
                                style: const TextStyle(fontSize: 20)),
                          ],
                        )),
                    Divider(),
                    Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Score:',
                                style: const TextStyle(fontSize: 20)),
                            Text(
                                '${gameplayData.score}',
                                style: const TextStyle(fontSize: 20)),
                          ],
                        )),
                    Divider(),
                    Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Number of Flaps:',
                                style: const TextStyle(fontSize: 20)),
                            Text(
                                '${gameplayData.numFlaps}',
                                style: const TextStyle(fontSize: 20)),
                          ],
                        )),
                  ],
                ),
                Padding(padding:const EdgeInsets.symmetric(vertical:20.0), child: ElevatedButton(
                    child: Text("Export", style: const TextStyle(fontSize: 30)),
                    onPressed: () {
                      export();
                    }))
              ],
            ),
          ),
        ]));
  }

  String DateTimeFromTimeSinceEpoch(int time) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(time);
    return DateFormat.yMd().add_jm().format(dt);
  }

  Future<void> export() async {
    GameplayData gameplayData = widget.gameplayData;
    Directory dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    File output = new File(
        "${dir.path}/flutter/${gameplayData.startTime}_${gameplayData.endTime}.csv");

    SessionDataModel sessionDataModel =
        Provider.of<SessionDataModel>(context, listen: false);

    final decodedJSON = json.decode(await getJSONfile());

    List<List<String>> csvData = [
      ["Device ID", sessionDataModel.currentUserDeviceName],
      ["Bluetooth ID"],
      ["Start Time", DateTimeFromTimeSinceEpoch(gameplayData.startTime)],
      ["End Time", DateTimeFromTimeSinceEpoch(gameplayData.endTime)],
      ["Score", gameplayData.score.toString()],
      ["Number of Flaps", gameplayData.numFlaps.toString()],
      ["All Data"]
    ];

    for (int i = 0; i < decodedJSON["processedData"].length; i++) {
      if (decodedJSON["processedData"][i].containsKey("voltage")) {
        csvData.add([decodedJSON["processedData"][i]["voltage"].toString()]);
      } else {
        csvData.add([decodedJSON["processedData"][i]["rawValue"].toString()]);
      }
    }

    String csvString = ListToCsvConverter().convert(csvData);

    if (!await output.exists()) {
      await output.create(recursive: true);
      output.writeAsStringSync(csvString);
    }

    ShareExtend.share(output.path, "file");
  }

  Future<String> getJSONfile() async {
    GameplayData gameplayData = widget.gameplayData;
    String savedPath = gameplayData.emgRecordingPath;
    File jsonFile = new File(savedPath);
    if (!await jsonFile.exists()) {
      return null;
    }
    return await jsonFile.readAsString();
  }
}
