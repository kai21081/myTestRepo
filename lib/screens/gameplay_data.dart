import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/models/user.dart';
import 'package:provider/provider.dart';

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_getUserData(context).toString()),
          ],
        ),
      ),
    );
  }

  Future<User> _getUserData(context) {
    return _getSessionDataModel(context).getUser(_getSessionDataModel(context).currentUserId);
  }

  SessionDataModel _getSessionDataModel(context) {
    return Provider.of<SessionDataModel>(context, listen: false);
  }

}

