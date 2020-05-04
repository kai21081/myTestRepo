import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:gameplayground/screens/main_menu.dart';

class GameSettingsPage extends StatefulWidget {
  static String pageTitle = 'Game Settings';

  GameSettingsPage({Key key}) : super(key: key);

  @override
  _GameSettingsPageState createState() => _GameSettingsPageState();
}

class _GameSettingsPageState extends State<GameSettingsPage> {
  static double flapStrengthDefaultValue = 5;
  static double flapStrengthDefaultMin = 1;
  static double flapStrengthDefaultMax = 10;
  double _sliderValue = _GameSettingsPageState.flapStrengthDefaultValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(GameSettingsPage.pageTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Slider(
                value: _sliderValue,
                min: _GameSettingsPageState.flapStrengthDefaultMin,
                max: _GameSettingsPageState.flapStrengthDefaultMax,
                divisions:
                    _GameSettingsPageState.flapStrengthDefaultMax.toInt() -
                        _GameSettingsPageState.flapStrengthDefaultMin.toInt(),
                onChanged: (value) {
                  print(value);
                  setState(() => _sliderValue = value);
                },
                label: _sliderValue.round().toString()),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Text(
                'Flap Strength',
                style: TextStyle(fontSize: 20),
              )
            ]),
            SizedBox(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
              FloatingActionButton.extended(
                label: Text(
                  'Accept',
                ),
                heroTag: 'accept',
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => MainMenuPage()));
                },
              ),
              SizedBox(width: 20)
            ]),
          ],
        ),
      ),
    );
  }
}
