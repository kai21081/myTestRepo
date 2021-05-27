import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/models/user.dart';
import 'package:provider/provider.dart';

import 'gameplay_data_detail.dart';

// Charts to consider:
// - games per day over time
// - max/average daily score over time
// - gameplay time over time
// - game duration over time

class GameplayDataPage extends StatefulWidget {
  final String title;

  GameplayDataPage({Key key, this.title}) : super(key: key);

  @override
  _GameplayDataPageState createState() => _GameplayDataPageState();
}

class _GameplayDataPageState extends State<GameplayDataPage> {


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


    return Scaffold(
      appBar: AppBar(
        title: Text("User Data"),
      ),
      body: FutureBuilder<UnmodifiableListView<GameplayData>>(
                future:_getUserData(context),
                builder: (context,AsyncSnapshot<UnmodifiableListView<GameplayData>> gameplayData) {
                  if (gameplayData.hasData) {
                    if (gameplayData.data.length == 0) {
                      return Text('No Gameplay Data is available.');
                    } else {
                      //Show list of gameplay data
                      return ListView.builder(
                        itemCount: gameplayData.data.length,
                        itemBuilder: (context, index) =>
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              GameplayDataDetailPage(
                                                  gameplayData: gameplayData
                                                      .data[index])
                                      ));
                                },
                                child: Card(
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [Row(children:[Icon(Icons.bar_chart_outlined,size:40),
                                        Column(crossAxisAlignment: CrossAxisAlignment.values[0],
                                          children: [
                                            Text(
                                                'Start Time: ${DateTimeFromTimeSinceEpoch(
                                                    gameplayData.data[index]
                                                        .startTime)}', style:const TextStyle(fontSize:15)),
                                            Text(
                                                'End Time: ${DateTimeFromTimeSinceEpoch(
                                                    gameplayData.data[index]
                                                        .endTime)}', style:const TextStyle(fontSize:15))
                                          ],
                                        )]),
                                        Align(alignment: Alignment.centerRight, child:Text('${gameplayData.data[index].score}', style:const TextStyle(fontWeight:FontWeight.bold, fontSize:35)))
                                      ],
                                    )
                                )
                            ),
                      );
                    }
                  } else {
                    return CircularProgressIndicator();
                  }
                }
          )
    );
  }
  Future<UnmodifiableListView<GameplayData>> _getUserData(context) {
    return _getSessionDataModel(context).getUserGameplayData(_getSessionDataModel(context).currentUser);
  }

  SessionDataModel _getSessionDataModel(context) {
    return Provider.of<SessionDataModel>(context, listen: false);
  }

  String DateTimeFromTimeSinceEpoch(int time) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(time);
    return '${dt.year}-${dt.month}-${dt.day} ${dt.hour}:${dt.minute}:${dt.second}';
  }
}

