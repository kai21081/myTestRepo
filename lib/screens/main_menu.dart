import 'package:flame/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gameplayground/models/bluetooth_manager.dart';
import 'package:gameplayground/screens/flappy_game.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/models/thresholded_trigger_data_processor.dart';
import 'package:gameplayground/screens/game_settings.dart';
import 'package:gameplayground/screens/gameplay_data.dart';
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
  static final String _labelGameplayDataButton = 'Gameplay Data';

  static final String _heroTagPlayGameButton = 'play_game_button';
  static final String _heroTagPracticeModeButton = 'practice_mode_button';
  static final String _heroTagGameSettingsButton = 'game_settings_button';
  static final String _heroTagCalibrateButton = 'calibrate_button';
  static final String _heroTagDisplayInputButton = 'display_input_button';
  static final String _heroTagGameplayDataButton = 'gameplay_data';

  static final double _betweenButtonSpacing = 20;

  static final String _callbackNameNotifyIsReadyToProvideValuesState =
      '_MainMenuPageState_Callback';

  BluetoothManager _bluetoothManager;
  bool _bluetoothManagerIsReadyToProvideValues;
  String _deviceName;

  @override
  void initState() {
    super.initState();
    _bluetoothManager =
        Provider.of<SessionDataModel>(context, listen: false).bluetoothManager;
    _deviceName = Provider.of<SessionDataModel>(context, listen: false)
        .currentUserDeviceName;

    _bluetoothManagerIsReadyToProvideValues =
        _bluetoothManager.isReadyToProvideValues;
    _bluetoothManager.addNotifyIsReadyToProvideValuesStateCallback(
        _callbackNameNotifyIsReadyToProvideValuesState,
        _handleBluetoothManagerIsReadyToProvideValueState);
    _bluetoothManager.connect(ConnectionSpec.fromDeviceName(_deviceName));
  }

  void _handleBluetoothManagerIsReadyToProvideValueState(
      bool isReadyToProvideValues) {
    print('received new isReadyToProvideValues of: $isReadyToProvideValues');
    setState(() {
      _bluetoothManagerIsReadyToProvideValues = isReadyToProvideValues;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId =
        Provider.of<SessionDataModel>(context, listen: false).currentUserId;

    String connectionMessage;
    Widget connectionWidget;
    if (_bluetoothManagerIsReadyToProvideValues) {
      connectionMessage = 'Connected to Surface EMG.';
      connectionWidget = Icon(Icons.bluetooth_connected);
    } else {
      connectionMessage = 'Connecting to Surface EMG.';
      connectionWidget = CircularProgressIndicator();
    }

    List<Widget> bodyColumnChildren = <Widget>[
      SizedBox(height: 40),
      _buildPlayGameButton(),
      SizedBox(height: _betweenButtonSpacing),
      _buildPracticeModeButton(),
      SizedBox(height: _betweenButtonSpacing),
      _buildGameSettingsButton(),
      SizedBox(height: _betweenButtonSpacing),
      _buildCalibrateButton(),
      SizedBox(height: _betweenButtonSpacing),
      _buildDisplayInputButton(),
      SizedBox(height: _betweenButtonSpacing),
      _buildGameplayDataButton(),
      Expanded(
        child: Container(),
      ),
      SizedBox(
        height: 40,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          SizedBox(width: 20),
          SizedBox(height: 30, width: 30, child: connectionWidget),
          SizedBox(width: 20),
          Text(connectionMessage, style: TextStyle(fontSize: 18))
        ]),
      )
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $currentUserId!'),
        centerTitle: true,
        leading: BackButton(onPressed: () async {
          _bluetoothManager.removeNotifyIsReadyToProvideValuesStateCallback(
              _callbackNameNotifyIsReadyToProvideValuesState);
          await _bluetoothManager.reset();
          Navigator.of(context).pop();
        }),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bodyColumnChildren,
        ),
      ),
    );
  }

  FloatingActionButton _buildPlayGameButton() {
    return _buildFloatingActionButtonBasedOnState(
      labelString: _labelPlayGameButton,
      heroTag: _heroTagPlayGameButton,
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          FlappyGame game = FlappyGame(
              context, ThresholdedTriggerDataProcessor(_bluetoothManager),
              practiceMode: false);
          TapGestureRecognizer tapper = TapGestureRecognizer();
          tapper.onTapDown = game.onTapDown;
          Util().addGestureRecognizer(tapper);
          return game.widget;
        }));
      },
    );
  }

  FloatingActionButton _buildPracticeModeButton() {
    return _buildFloatingActionButtonBasedOnState(
      labelString: _labelPracticeModeButton,
      heroTag: _heroTagPracticeModeButton,
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          FlappyGame game = FlappyGame(
              context, ThresholdedTriggerDataProcessor(_bluetoothManager),
              practiceMode: true);
          TapGestureRecognizer tapper = TapGestureRecognizer();
          tapper.onTapDown = game.onTapDown;
          Util().addGestureRecognizer(tapper);
          return game.widget;
        }));
      },
    );
  }

  FloatingActionButton _buildGameSettingsButton() {
    return _buildFloatingActionButtonBasedOnState(
      labelString: _labelGameSettingsButton,
      heroTag: _heroTagGameSettingsButton,
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => GameSettingsPage()));
      },
    );
  }

  FloatingActionButton _buildCalibrateButton() {
    return _buildFloatingActionButtonBasedOnState(
      labelString: _labelCalibrateButton,
      heroTag: _heroTagCalibrateButton,
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CalibrationPage()));
      },
    );
  }

  FloatingActionButton _buildDisplayInputButton() {
    return _buildFloatingActionButtonBasedOnState(
      labelString: _labelDisplayInputButton,
      heroTag: _heroTagDisplayInputButton,
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => InputTimeseriesPage()));
      },
    );
  }

  FloatingActionButton _buildGameplayDataButton() {
    return _buildFloatingActionButtonBasedOnState(
      labelString: _labelGameplayDataButton,
      heroTag: _heroTagGameplayDataButton,
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => GameplayDataPage()));
      },
    );
  }

  FloatingActionButton _buildFloatingActionButtonBasedOnState(
      {@required String labelString,
      @required String heroTag,
      @required VoidCallback onPressed}) {
    print(
        'building button: $labelString with state: $_bluetoothManagerIsReadyToProvideValues.');
    VoidCallback onPressedForState;
    final theme = Theme.of(context);
    Color backgroundColor;
    if (_bluetoothManagerIsReadyToProvideValues) {
      onPressedForState = onPressed;
      backgroundColor = theme.colorScheme.primary;
      print('buttonColor: $backgroundColor');
    } else {
      onPressedForState = null;
      backgroundColor = Colors.grey[300];
      print('disabledColor: $backgroundColor');
    }

    return FloatingActionButton.extended(
      label: Text(labelString),
      heroTag: heroTag,
      onPressed: onPressedForState,
      disabledElevation: 0.0,
      backgroundColor: backgroundColor,
    );
  }
}
