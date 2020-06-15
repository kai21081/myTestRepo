import 'package:flame/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gameplayground/screens/flappy_game.dart';
import 'package:gameplayground/models/mock_bluetooth_manager.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/models/thresholded_trigger_data_processor.dart';
import 'package:gameplayground/screens/game_settings.dart';
import 'package:gameplayground/screens/input_timeseries.dart';
import 'package:provider/provider.dart';

import 'calibration.dart';

class MainMenuPage extends StatefulWidget {
  final String title;

  MainMenuPage({Key key, this.title}) : super(key: key);

  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  static final String _labelPlayGameButton = 'Play Game';
  static final String _labelPracticeModeButton = 'Practice Mode';
  static final String _labelGameSettingsButton = 'Game Settings';
  static final String _labelCalibrateButton = 'Calibrate';
  static final String _labelDisplayInputButton = 'Display Input';

  static final String _heroTagPlayGameButton = 'play_game_button';
  static final String _heroTagPracticeModeButton = 'practice_mode_button';
  static final String _heroTagGameSettingsButton = 'game_settings_button';
  static final String _heroTagCalibrateButton = 'calibrate_button';
  static final String _heroTagDisplayInputButton = 'display_input_button';

  static final double _betweenButtonSpacing = 20;

  @override
  Widget build(BuildContext context) {
    String currentUserId =
        Provider.of<SessionDataModel>(context, listen: false).currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $currentUserId!'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton.extended(
              label: Text(_labelPlayGameButton),
              heroTag: _heroTagPlayGameButton,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  FlappyGame game = FlappyGame(
                      context,
                      ThresholdedTriggerDataProcessor(
                          MockBluetoothManager(100, 2, 10, 5, 50)),
                      practiceMode: false);
                  TapGestureRecognizer tapper = TapGestureRecognizer();
                  tapper.onTapDown = game.onTapDown;
                  Util().addGestureRecognizer(tapper);
                  return game.widget;
                }));
              },
            ),
            SizedBox(height: _betweenButtonSpacing),
            FloatingActionButton.extended(
              label: Text(_labelPracticeModeButton),
              heroTag: _heroTagPracticeModeButton,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  FlappyGame game = FlappyGame(
                      context,
                      ThresholdedTriggerDataProcessor(
                          MockBluetoothManager(100, 10, 10, 5, 50)),
                      practiceMode: true);
                  TapGestureRecognizer tapper = TapGestureRecognizer();
                  tapper.onTapDown = game.onTapDown;
                  Util().addGestureRecognizer(tapper);
                  return game.widget;
                }));
              },
            ),
            SizedBox(height: _betweenButtonSpacing),
            FloatingActionButton.extended(
              label: Text(_labelGameSettingsButton),
              heroTag: _heroTagGameSettingsButton,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GameSettingsPage()));
              },
            ),
            SizedBox(height: _betweenButtonSpacing),
            FloatingActionButton.extended(
              label: Text(_labelCalibrateButton),
              heroTag: _heroTagCalibrateButton,
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CalibrationPage()));
              },
            ),
            SizedBox(height: _betweenButtonSpacing),
            FloatingActionButton.extended(
              label: Text(_labelDisplayInputButton),
              heroTag: _heroTagDisplayInputButton,
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
}
