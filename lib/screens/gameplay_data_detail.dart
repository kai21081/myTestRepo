import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/gen/flutterblue.pb.dart';
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';
import 'package:path/path.dart' as path;
import 'package:csv/csv.dart';

class GameplayDataDetailPage extends StatefulWidget {
  final String title;
  final GameplayData gameplayData;

  GameplayDataDetailPage({Key key, this.title, this.gameplayData}) : super(key: key);

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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
                children: [Row(
                  children: [
                    Text('Start Time:'),
                    Text('${DateTimeFromTimeSinceEpoch(gameplayData.startTime)}')
                  ],
                ),Row(
                  children: [
                    Text('End Time:'),
                    Text('${DateTimeFromTimeSinceEpoch(gameplayData.endTime)}')
                  ],
                ),Row(
                  children: [
                    Text('Score:'),
                    Text('${gameplayData.score}'),
                    SizedBox(width: 20,),
                    Text('Number of Flaps:'),
                    Text('${gameplayData.numFlaps}')
                  ],
                ),
                  Row(
                    children: [
                      Text('Peak Flaps:'),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(child:Expanded(child:Text("Export")), onPressed: () {export();}),
                    ],
                  )
                ]
            )
          )
        ]
      )
    );
  }

  String DateTimeFromTimeSinceEpoch(int time) {
    return DateTime.fromMillisecondsSinceEpoch(time).toString();
  }

  List<Series<int,int>> createRandomList() {
    Random random = new Random();
    List l = [];
    for(int i = 0; i < 50; i++) {
      l.add(new Series<int,int>());
    }
  }

  Future<void> export() async{
    GameplayData gameplayData = widget.gameplayData;
    Directory dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    File output = new File("${dir.path}/flutter/${gameplayData.startTime}_${gameplayData.endTime}.csv");

    SessionDataModel sessionDataModel = Provider.of<SessionDataModel>(context, listen: false);
    Directory supportDirectory = await getApplicationSupportDirectory();

    String savedPath = path.join(supportDirectory.path,'timestamp_${gameplayData.startTime}_user_$sessionDataModel.currentUserId' + ".json");

    final decodedJSON = await json.decode(await rootBundle.loadString(savedPath));

    List<List<String>> csvData = [["Device ID",sessionDataModel.currentUserDeviceName],
    ["Bluetooth ID", ], ["Start Time",DateTimeFromTimeSinceEpoch(gameplayData.startTime)],
    ["End Time", DateTimeFromTimeSinceEpoch(gameplayData.endTime)],
    ["Score", gameplayData.score.toString()],
    ["Number of Flaps", gameplayData.numFlaps.toString()],
    ["Initial Baseline Average"]];

    for (int i; i < decodedJSON["processedData"].length(); i++) {
      if (decodedJSON["processedData"][i].contains("voltage")) {
        csvData.add(decodedJSON["processedData"][i]["voltage"]);
      } else {
        csvData.add(decodedJSON["processedData"][i]["rawValue"]);
      }
    }

    String csvString = ListToCsvConverter().convert(csvData);

    if(!await output.exists()) {
      await output.create(recursive: true);
      output.writeAsStringSync(csvString);
    }

    ShareExtend.share(output.path, "file");
  }

}