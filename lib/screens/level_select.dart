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
import 'package:flutter/services.dart' show rootBundle;
import 'package:gameplayground/models/user.dart';



import 'calibration.dart';

class LevelSelectPage extends StatefulWidget {
  final String title;

  LevelSelectPage({Key key, this.title}) : super(key: key);

  @override
  _LevelSelectPageState createState() => _LevelSelectPageState();
}

class _LevelSelectPageState extends State<LevelSelectPage> {

  static final String _heroTagLevel1Button = 'level_one_button';
  static final String _heroTagLevel2Button = 'level_two_button';
  static final String _heroTagLevel3Button = 'level_three_button';
  static final String _heroTagLevel4Button = 'level_four_button';
  static final String _heroTagLevel5Button = 'level_five_button';
  User _user;

  static final String _connectingToSurfaceEmgMessage =
      'Connecting to Surface EMG.';
  static final String _connectedToSurfaceEmgMessage =
      'Connected to Surface EMG.';

  static final double _betweenButtonSpacing = 20;

  static final String _callbackNameNotifyIsReadyToProvideValuesState =
      '_LevelSelectPageState_Callback';

  BluetoothManager _bluetoothManager;
  bool _bluetoothManagerIsReadyToProvideValues;
  String _deviceName;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<SessionDataModel>(context, listen: false).getCurrentUser();
    print(_user.mostRecentActivityTimestamp);
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
      connectionMessage = _connectedToSurfaceEmgMessage;
      connectionWidget = Icon(Icons.bluetooth_connected);
    } else {
      connectionMessage = _connectingToSurfaceEmgMessage;
      connectionWidget = CircularProgressIndicator();
    }

    List<Widget> bodyColumnChildren = <Widget>[
      SizedBox(height: 40),
      _buildPlayGameButton(1, "Level 1", "assets/levels/level1.txt", _heroTagLevel1Button),
      SizedBox(height: _betweenButtonSpacing),
      _buildPlayGameButton(2, "Level 2", "assets/levels/level2.txt", _heroTagLevel2Button),
      SizedBox(height: _betweenButtonSpacing),
      _buildPlayGameButton(3, "Level 3", "assets/levels/level3.txt", _heroTagLevel3Button),
      SizedBox(height: _betweenButtonSpacing),
      _buildPlayGameButton(4, "Level 4", "assets/levels/level4.txt", _heroTagLevel4Button),
      SizedBox(height: _betweenButtonSpacing),
      _buildPlayGameButton(5, "Level 5", "assets/levels/level5.txt", _heroTagLevel5Button),
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
        title: Text('Select a level!'),
        centerTitle: true,
        leading: BackButton(onPressed: () async {
          _bluetoothManager.removeNotifyIsReadyToProvideValuesStateCallback(
              _callbackNameNotifyIsReadyToProvideValuesState);
          _bluetoothManager.reset();
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

  FloatingActionButton _buildPlayGameButton(int levelNum, String levelName, String levelPath, String heroTag) {
    return _buildGameStartingButton(levelNum, levelName,
        heroTag, levelPath, /*startPracticeMode=*/ true);
  }


  FloatingActionButton _buildGameStartingButton(int levelNum,
      String label, String heroTag, String levelPath, bool startPracticeMode) {
    return _buildFloatingActionButtonBasedOnState(
      labelString: label,
      heroTag: heroTag,
      levelNum: levelNum,
      onPressed: () async {
        await _bluetoothManager.startStreamingValues();
        MaterialPageRoute route = MaterialPageRoute(builder: (context) {
          FlappyGame game = FlappyGame(
              context, ThresholdedTriggerDataProcessor(_bluetoothManager),
              levelPath, practiceMode: startPracticeMode);
          TapGestureRecognizer tapper = TapGestureRecognizer();
          tapper.onTapDown = game.onTapDown;
          Util().addGestureRecognizer(tapper);
          return game.widget;
        });
        route.popped.then((_) {
          _user = Provider.of<SessionDataModel>(context, listen: false).getCurrentUser();
          _bluetoothManager.stopStreamingValues();

        });
        Navigator.push(context, route);
      },
    );
  }

  FloatingActionButton _buildFloatingActionButtonBasedOnState(
      {@required String labelString,
        @required String heroTag,
        @required VoidCallback onPressed,
        @required int levelNum}) {
//    print(
//        'building button: $labelString with state: $_bluetoothManagerIsReadyToProvideValues.');
    VoidCallback onPressedForState;
    final theme = Theme.of(context);
    Color backgroundColor;
    if (_bluetoothManagerIsReadyToProvideValues && _user.lastLevelCompleted >= levelNum + - 1) {
      onPressedForState = onPressed;
      backgroundColor = theme.colorScheme.primary;
      print('buttonColor: $backgroundColor');
    } else {
      onPressedForState = null;
      backgroundColor = Colors.grey[300];
//      print('disabledColor: $backgroundColor');
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
