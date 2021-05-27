import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children:[Text('Start Time:',style:const TextStyle(fontSize:20)),Text('End Time:',style:const TextStyle(fontSize:20)),
                    Text('Score:',style:const TextStyle(fontSize:20)),Text('Number of Flaps:',style:const TextStyle(fontSize:20))]),
                Column(crossAxisAlignment: CrossAxisAlignment.end,
                children:[Text('${DateTimeFromTimeSinceEpoch(gameplayData.startTime)}',style:const TextStyle(fontSize:20)),
                  Text('${DateTimeFromTimeSinceEpoch(gameplayData.endTime)}',style:const TextStyle(fontSize:20)),
                  Text('${gameplayData.score}',style:const TextStyle(fontSize:20)),
                  Text('${gameplayData.numFlaps}',style:const TextStyle(fontSize:20))])
              ]
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(child:Text("Export",style:const TextStyle(fontSize:30)), onPressed: () {export();}),
            ],
          )
        ]
      )
    );
  }

  String DateTimeFromTimeSinceEpoch(int time) {
    return DateTime.fromMillisecondsSinceEpoch(time).toString();
  }


  Future<void> export() async{
    GameplayData gameplayData = widget.gameplayData;
    Directory dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    File output = new File("${dir.path}/flutter/${gameplayData.startTime}_${gameplayData.endTime}.csv");

    SessionDataModel sessionDataModel = Provider.of<SessionDataModel>(context, listen: false);
    Directory supportDirectory = await getApplicationSupportDirectory();
    String savedPath = path.join(supportDirectory.path, 'timestamp_${gameplayData.startTime}_user_${sessionDataModel.currentUserId}.json');

    String jsonString = await rootBundle.loadString(savedPath);
    final decodedJSON = await json.decode(jsonString);

    List<List<String>> csvData = [["Device ID",sessionDataModel.currentUserDeviceName],
    ["Bluetooth ID", ], ["Start Time",DateTimeFromTimeSinceEpoch(gameplayData.startTime)],
    ["End Time", DateTimeFromTimeSinceEpoch(gameplayData.endTime)],
    ["Score", gameplayData.score.toString()],
    ["Number of Flaps", gameplayData.numFlaps.toString()],
    ["All Data"]];

    for (int i = 0; i < decodedJSON["processedData"].length; i++) {
      if (decodedJSON["processedData"][i].containsKey("voltage")) {
        csvData.add([decodedJSON["processedData"][i]["voltage"].toString()]);
      } else {
        csvData.add([decodedJSON["processedData"][i]["rawValue"].toString()]);
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