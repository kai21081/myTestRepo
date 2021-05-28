import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:intl/intl.dart';

class GameplayDataDetailPage extends StatefulWidget {
  final String title;
  final List<GameplayData> gameplayData;

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
    return Scaffold(
        appBar: AppBar(
          title: Text("Day Data Page"),
        ),
        body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:buildSummaryWidgets() + buildWidgets(),
            ),
          );
  }

  String DateTimeFromTimeSinceEpoch(int time) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(time);
    return DateFormat.yMd().add_jm().format(dt);
  }

  Duration maxGameTime(Duration i, GameplayData j) {
    if(i.compareTo(DateTime.fromMillisecondsSinceEpoch(j.startTime).difference(DateTime.fromMillisecondsSinceEpoch(j.endTime))) < 0) {
      return DateTime.fromMillisecondsSinceEpoch(j.startTime).difference(DateTime.fromMillisecondsSinceEpoch(j.endTime));
    }
    return i;
  }

  List<Widget> buildSummaryWidgets(){
    List<GameplayData> gameplayDataList = widget.gameplayData;
    List<Widget> widgets = [];
    Duration totalGameTime = gameplayDataList.fold(new Duration(),(i,j)=>i +
        (DateTime.fromMillisecondsSinceEpoch(j.startTime).difference(DateTime.fromMillisecondsSinceEpoch(j.endTime))));
    Duration maxGameTime = gameplayDataList.fold(new Duration(),(i,j)=> this.maxGameTime(i,j));
    int highestScore = gameplayDataList.fold(0,(i,j) => max(i,j.score));
    //int highestLevel = gameplayDataList.fold(0,(i,j) => max(i,j.level));

    widgets.add(Padding(padding:const EdgeInsets.all(20.0),child:Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("Total Game Time"),Text(totalGameTime.toString())])));
    widgets.add(Padding(padding:const EdgeInsets.all(20.0),child:Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("Longest Game Time"),Text(maxGameTime.toString())])));
    widgets.add(Padding(padding:const EdgeInsets.all(20.0),child:Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("Highest Score"),Text(highestScore.toString())])));
    widgets.add(Padding(padding:const EdgeInsets.all(20.0),child:Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("Highest Level"),Text("NOT IMPLEMENTED YET")])));
  }

  List<Widget> buildWidgets() {
    List<GameplayData> gameplayDataList = widget.gameplayData;
    List<Widget> widgets = [];
    for(int index = 0; index < gameplayDataList.length; index++) {
      widgets.add(new GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GameplayDataDetailPage(
                        gameplayData: [gameplayDataList.elementAt(index)])));
          },
          child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.bar_chart_outlined, size: 40),
                      SizedBox(
                        width: 5,
                      ),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.values[0],
                        children: [
                          Text(
                              'Start Time: ${DateTimeFromTimeSinceEpoch(gameplayDataList[index].startTime)}',
                              style: const TextStyle(fontSize: 15)),
                          Text(
                              'End Time: ${DateTimeFromTimeSinceEpoch(gameplayDataList[index].endTime)}',
                              style: const TextStyle(fontSize: 15))
                        ],
                      )
                    ]),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                            '${gameplayDataList[index].score}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 35)))
                  ],
                ),
              ))));
    }
    return widgets;
  }
}
