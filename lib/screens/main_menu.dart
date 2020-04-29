import 'package:flame/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gameplayground/flappy_game.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/screens/input_timeseries.dart';
import 'package:provider/provider.dart';

import 'calibration.dart';

class MainMenuPage extends StatefulWidget {
  final String title;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  MainMenuPage({Key key, this.title}) : super(key: key);

  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
            'Welcome, ${Provider.of<SessionDataModel>(context, listen: false).currentUserId}!'),
        centerTitle: true,
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton.extended(
              label: Text('Play Game'),
              heroTag: 'play_game',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  FlappyGame game = FlappyGame(context);
                  TapGestureRecognizer tapper = TapGestureRecognizer();
                  tapper.onTapDown = game.onTapDown;
                  Util().addGestureRecognizer(tapper);
                  return game.widget;
                }));
              },
            ),
            SizedBox(height: 20),
            FloatingActionButton.extended(
              label: Text('Calibrate'),
              heroTag: 'calibrate',
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CalibrationPage()));
              },
            ),
            SizedBox(height: 20),
            FloatingActionButton.extended(
              label: Text('Display Input'),
              heroTag: 'display_input',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InputTimeseriesPage()));
              },
            )
          ],
        ),
      ),
    );
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
}
