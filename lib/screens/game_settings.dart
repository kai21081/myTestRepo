import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:gameplayground/models/session.dart';
import 'package:gameplayground/models/game_settings.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/screens/main_menu.dart';
import 'package:provider/provider.dart';

class GameSettingsPage extends StatefulWidget {
  static String pageTitle = 'Game Settings';

  GameSettingsPage({Key key}) : super(key: key);

  @override
  _GameSettingsPageState createState() => _GameSettingsPageState();
}

class _GameSettingsPageState extends State<GameSettingsPage> {
  final double sliderMinValue = 1.0;
  final double sliderMaxValue = 10.0;
  static const String horizontalVelocitySliderLabel = 'Horizontal Velocity';
  double _horizontalVelocitySliderValue;

  static const String flapStrengthSliderLabel = 'Flap Strength';
  double _flapStrengthSliderValue;

  static const String terminalVelocitySliderLabel = 'Terminal Velocity';
  double _terminalVelocitySliderValue;

  static const String cherryDensitySliderLabel = 'Cherry Density';
  double _cherryDensitySliderValue;

  static const String playMusicSwitchLabel = 'Play Music';
  bool _playMusicSwitchValue;

  static const String musicVolumeSliderLabel = 'Music Volume';
  double _musicVolumeSliderValue;

  void initState() {
    super.initState();
    SessionDataModel sessionDataModel =
        Provider.of<SessionDataModel>(context, listen: false);
    UserModifiableSettings userModifiableSettings =
        sessionDataModel.gameSettings.userModifiableSettings;

    _horizontalVelocitySliderValue = GameSettings
        .mapScrollVelocityInScreenWidthsPerSecondToSliderValue(
            userModifiableSettings.scrollVelocityInScreenWidthsPerSecond);
    _flapStrengthSliderValue = GameSettings
        .mapFlapVelocityInScreenHeightFractionPerSecondToSliderValue(
            userModifiableSettings.flapVelocityInScreenHeightFractionPerSecond);
    _terminalVelocitySliderValue = GameSettings
        .mapTerminalVelocityInScreenHeightFractionPerSecondToSliderValue(
            userModifiableSettings
                .terminalVelocityInScreenHeightFractionPerSecond);
    _cherryDensitySliderValue =
        GameSettings.mapCherrySpawnRatePerSecondToSliderValue(
            userModifiableSettings.cherrySpawnRatePerSecond);
    _playMusicSwitchValue = userModifiableSettings.playMusic;
    _musicVolumeSliderValue = GameSettings.mapMusicVolumeToSliderValue(
        userModifiableSettings.musicVolume);
  }

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
            SizedBox(height: 40),
            _buildSlider(context, _horizontalVelocitySliderValue,
                sliderMinValue, sliderMaxValue, (value) {
              setState(() => _horizontalVelocitySliderValue = value);
            }, horizontalVelocitySliderLabel),
            SizedBox(height: 15),
            _buildSlider(context, _flapStrengthSliderValue, sliderMinValue,
                sliderMaxValue, (value) {
              setState(() => _flapStrengthSliderValue = value);
            }, flapStrengthSliderLabel),
            SizedBox(height: 15),
            _buildSlider(context, _terminalVelocitySliderValue, sliderMinValue,
                sliderMaxValue, (value) {
              setState(() => _terminalVelocitySliderValue = value);
            }, terminalVelocitySliderLabel),
            SizedBox(height: 15),
            _buildSlider(context, _cherryDensitySliderValue, sliderMinValue,
                sliderMaxValue, (value) {
              setState(() => _cherryDensitySliderValue = value);
            }, cherryDensitySliderLabel),
            SizedBox(height: 15),
            _buildToggleSwitch(context, _playMusicSwitchValue, (value) {
              setState(() => _playMusicSwitchValue = value);
            }, playMusicSwitchLabel),
            SizedBox(height: 15),
            _buildSlider(context, _musicVolumeSliderValue, sliderMinValue,
                sliderMaxValue, (value) {
              setState(() => _musicVolumeSliderValue = value);
            }, musicVolumeSliderLabel),
            SizedBox(height: 50),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
              FloatingActionButton.extended(
                label: Text(
                  'Accept',
                ),
                heroTag: 'accept',
                onPressed: () {
                  Provider.of<SessionDataModel>(context, listen: false)
                      .updateGameSettings(_buildGameSettings());
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

  GameSettings _buildGameSettings() {
    return GameSettings(
        scrollVelocityInScreenWidthsPerSecond: GameSettings
            .mapSliderValueToScrollVelocityInScreenWidthsPerSecond(
                _horizontalVelocitySliderValue),
        flapVelocityInScreenHeightFractionPerSecond: GameSettings
            .mapSliderValueToFlapVelocityInScreenHeightFractionPerSecond(
                _flapStrengthSliderValue),
        terminalVelocityInScreenHeightFractionPerSecond: GameSettings
            .mapSliderValueToTerminalVelocityInScreenHeightFractionPerSecond(
                _terminalVelocitySliderValue),
        cherrySpawnRatePerSecond:
            GameSettings.mapSliderValueToCherrySpawnRatePerSecond(
                _cherryDensitySliderValue),
        playMusic: _playMusicSwitchValue,
        musicVolume:
            GameSettings.mapSliderValueToMusicVolume(_musicVolumeSliderValue));
  }
}

Widget _buildSlider(
    BuildContext context,
    double sliderValue,
    double sliderMinValue,
    double sliderMaxValue,
    Function onChangedFunction,
    String sliderLabel) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Slider(
          value: sliderValue,
          min: sliderMinValue,
          max: sliderMaxValue,
          divisions: sliderMaxValue.toInt() - sliderMinValue.toInt(),
          onChanged: onChangedFunction,
          label: sliderValue.round().toString()),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Text(
          sliderLabel,
          style: TextStyle(fontSize: 20),
        )
      ]),
    ],
  );
}

Widget _buildToggleSwitch(BuildContext context, bool switchValue,
    Function onChangedFunction, String switchLabel) {
  return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Text(switchLabel, style: TextStyle(fontSize: 20)),
        Switch(value: switchValue, onChanged: onChangedFunction),
      ]);
}
