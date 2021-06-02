import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/models/user.dart';
import 'package:gameplayground/screens/gameplay_data_day.dart';
import 'package:intl/intl.dart';
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

  List<GameplayData> _gameplayData;
  SessionDataModel _databaseService;
  bool fetchingData = true;
  @override
  void initState() {
    super.initState();

    //JK: I put a print statement for you to see the order of operation. you can delete them before checking back in
    // InitState -> didChangeDependencies -> build
    print('init State');
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print('did Change Dependencies');
    _databaseService = Provider.of<SessionDataModel>(context, listen: false);
    _getGameplayData();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  void _getGameplayData() async {
      User currentUser = _databaseService.currentUser;
      _gameplayData = await _databaseService.getUserGameplayData(currentUser);
      setState(() {
        fetchingData = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return Scaffold(
        appBar: AppBar(
          title: Text("User Data"),
        ),
        body:
            fetchingData ? CircularProgressIndicator() : Text('Total number of gameplay data: ${_gameplayData.length}')
        // FutureBuilder<UnmodifiableListView<GameplayData>>(
        //     future: _getUserData(context),
        //     builder: (context,
        //         AsyncSnapshot<UnmodifiableListView<GameplayData>>
        //             gameplayData) {
        //       if (gameplayData.hasData) {
        //         if (gameplayData.data.length == 0) {
        //           return Text('No Gameplay Data is available.');
        //         } else {
        //
        //           //Show list of gameplay data
        //           return Column(children:[FutureBuilder<Widget>(
        //             future: summaryWidgetList(gameplayData.data, context),
        //                 builder: (context, AsyncSnapshot<Widget> summaryList) {
        //               if(summaryList.hasData) {
        //                 return summaryList.data;
        //               } else {
        //                 return CircularProgressIndicator();
        //               }
        //           }
        //           ),
        //             getWidgets(gameplayData.data)]
        //           );
        //         }
        //       } else {
        //         return CircularProgressIndicator();
        //       }
        //     })
    );
  }

  Future<UnmodifiableListView<GameplayData>> _getUserData(context) {
    return _getSessionDataModel(context)
        .getUserGameplayData(_getSessionDataModel(context).currentUser);
  }

  Widget getWidgets(List<GameplayData> gameplayData) {
    dayWidgetListBuilder widgetBuilder = dayWidgetListBuilder([]);
    for(int i = 0; i < gameplayData.length; i++) {
      widgetBuilder.addGameplayData(gameplayData[i]);
    }
    return widgetBuilder.buildWidgets(context);
  }

  Future<User> _getUserStats(context) {
    return _getSessionDataModel(context)
        .getUser(_getSessionDataModel(context).currentUserId);
  }

  SessionDataModel _getSessionDataModel(context) {
    return Provider.of<SessionDataModel>(context, listen: false);
  }

  String DateTimeFromTimeSinceEpoch(int time) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(time);
    return DateFormat.yMd().add_jm().format(dt);
  }

  Future<Widget> summaryWidgetList(
      List<GameplayData> gameplayDataList, context) async {
    User userData = await _getUserStats(context);
    int totalGamesPlayed = gameplayDataList.length;
    int highScore = userData.highScore;
    //String highScoreDate = userData.highScoreDate;
    //int highestLevel = userDate.highestLevel;
    //String highestLevelDate = userData.highestLevelDate
    return Padding(padding:EdgeInsets.all(20.0),child:Column(children:[
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children:[
      Text("Total Games Played"), Text(totalGamesPlayed.toString())]),
      Divider(),
      //Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
        //Text("Highest Score: ${highScore}"),Text(highScoreDate)]),
      Divider(),
      //Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
        //Text("Highest Level: ${highestLevel}"),Text(highestLevelDate)]),
      Divider(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
        Text("Streaks"),Column(children:[Text("Played at least 1 game: ${getGameStreak(gameplayDataList).toString()}"),
        Text("Played at least 30 mins: ${get30minStreak(gameplayDataList).toString()}")])
      ]),
      Divider(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Average Duration (Past 3 days)"),Text(getAvgDuration(gameplayDataList))]),
      Divider(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
        Text("Total Score (Past 3 Days)"), Text(getTotalScore(gameplayDataList))])
    ]));
  }

  String getAvgDuration(List<GameplayData> gameplayDataList) {
    if(getDateTime(gameplayDataList.first)
       .difference(getDateTime(gameplayDataList.last))
        .compareTo(Duration(days:3)) < 0)
      return "NA";
    int i = 0;
    Duration totalDuration = Duration();
    while(i < gameplayDataList.length && Duration(milliseconds:gameplayDataList.first.startTime-gameplayDataList[i].startTime)
        .compareTo(Duration(days:3)) <= 0) {
      totalDuration += DateTime.fromMillisecondsSinceEpoch(gameplayDataList[i].endTime)
          .difference(getDateTime(gameplayDataList[i]));
      i++;
    }
    int milliseconds = (totalDuration.inMilliseconds/i).floor();
    return durationToString(Duration(milliseconds:milliseconds));
  }

  String durationToString(Duration d) {
    if(d.inSeconds < 60) {
      return "${d.inSeconds.round().toString()} s";
    }
    return "${d.inMinutes.round().toString()} mins ${d.inSeconds.remainder(60).round().toString()} s";
  }

  String getTotalScore(List<GameplayData> gameplayDataList) {
    if(getDateTime(gameplayDataList.first)
        .difference(getDateTime(gameplayDataList.last))
        .compareTo(Duration(days:3)) < 0)
      return "NA";
    int i = 0;
    int totalScore = 0;
    while(getDateTime(gameplayDataList.first)
        .difference(getDateTime(gameplayDataList[i]))
        .compareTo(Duration(days:3)) <= 0) {
      totalScore += gameplayDataList[i].score;
      i++;
    }
    return totalScore.toString();
  }

  int getGameStreak(List<GameplayData> gameplayDataList) {
    if(gameplayDataList.isEmpty ||
        !(DateUtils.isSameDay(getDateTime(gameplayDataList.first),DateTime.now()) ||
        DateUtils.isSameDay(getDateTime(gameplayDataList.first).add(Duration(days:1)),DateTime.now()))){
      return 0;
    }

    int output = 1;
    for(int i = 1; i < gameplayDataList.length; i++) {
      if (DateUtils.isSameDay(getDateTime(gameplayDataList[i-1]),
          getDateTime(gameplayDataList[i]).add(Duration(days:1))))
        output++;
      else if(!DateUtils.isSameDay(getDateTime(gameplayDataList[i-1]),
          getDateTime(gameplayDataList[i])))
        return output;
    }
    return output;
  }

  int get30minStreak(List<GameplayData> gameplayDataList) {
    if(gameplayDataList.isEmpty ||
        !(DateUtils.isSameDay(getDateTime(gameplayDataList.first),DateTime.now()) ||
            DateUtils.isSameDay(getDateTime(gameplayDataList.first).add(Duration(days:1)),DateTime.now()))){
      return 0;
    }

    int output = 0;
    Duration dayDuration = Duration();
    for(int i = 0; i < gameplayDataList.length; i++) {
      if (DateUtils.isSameDay(getDateTime(gameplayDataList[max(i-1,0)]),
          getDateTime(gameplayDataList[i]).add(Duration(days:1))) && dayDuration.inMinutes >= 30) {
        output++;
        dayDuration = getDateTime(gameplayDataList[i]).difference(DateTime.fromMillisecondsSinceEpoch(gameplayDataList[i].endTime));
      }
      else if(!DateUtils.isSameDay(getDateTime(gameplayDataList[max(i-1,0)]),
          getDateTime(gameplayDataList[i])))
        return output;
      else
        dayDuration += getDateTime(gameplayDataList[i]).difference(DateTime.fromMillisecondsSinceEpoch(gameplayDataList[i].endTime));
    }
    return output;
  }
  


  DateTime getDateTime(GameplayData gameplayData) {
    return DateTime.fromMillisecondsSinceEpoch(gameplayData.startTime);
  }
}

class dayWidgetListBuilder {
  List<singleDayWidgetBuilder> days;

  dayWidgetListBuilder(this.days);

  void addGameplayData(GameplayData input) {
    if(days.isNotEmpty) {
        if(days.last.isCorrectDate(input)) {
          days.last.addGameplayData(input);
          return;
      }
    }
    singleDayWidgetBuilder singleDay = singleDayWidgetBuilder(
        DateTime.fromMillisecondsSinceEpoch(input.startTime),
        []);
    singleDay.addGameplayData(input);
    days.add(singleDay);
  }

  Widget buildWidgets(BuildContext context) {
    List<Widget> inputWidgets = [];
    for(int i = 0; i < days.length; i++) {
      inputWidgets.add(days[i].buildWidget(context));
    }
    return Column(children:inputWidgets);
  }
}

class singleDayWidgetBuilder {
  DateTime date;
  List<GameplayData> gameplayDataList;

  singleDayWidgetBuilder(this.date, this.gameplayDataList);

  bool isCorrectDate(GameplayData input) {
    return DateUtils.isSameDay(DateTime.fromMillisecondsSinceEpoch(input.startTime),date);
  }

  void addGameplayData(GameplayData input) {
    gameplayDataList.add(input);
  }

  Widget buildWidget(BuildContext context) {
    return GestureDetector(onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GameplayDataDayPage(
                  gameplayData: gameplayDataList)));
    },
        child:Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                decoration: BoxDecoration(
                  color:Colors.grey.shade300,
                    border: Border.all(
                      color: Colors.black,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(height:50.0,width:50.0,margin:EdgeInsets.fromLTRB(0.0, 0.0, 5.0, 0.0), alignment:Alignment(0.0,0.0),
                                decoration: BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle),
                                child: Text(getCorrectDay(),style: const TextStyle(fontSize:20.0))),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(date.toString()),
                                  Text("Games played: ${gameplayDataList.length}")
                                ])
                          ]),
                          Icon(Icons.arrow_forward_ios)
                        ]
                    )
                )
            )
        )
    );
  }

  String getCorrectDay() {
    Map<int,String> weekdayMap = {
      1:"M",
      2:"Tu",
      3:"W",
      4:"Th",
      5:"F",
      6:"S",
      7:"Su"
    };
    return weekdayMap[date.weekday];
  }
}
