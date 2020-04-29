import 'package:flame/flame.dart';
import 'package:flame/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/models/surface_emg_game_database.dart';
import 'package:gameplayground/screens/select_user.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Util flameUtil = Util();
  flameUtil.fullScreen();
  flameUtil.setOrientation(DeviceOrientation.portraitUp);
  Flame.images.loadAll(<String>[
    'targets/cherry.png',
    'obstacles/column.png',
    'birds/bird_dead.png',
    'birds/bird_wing_down.png',
    'birds/bird_wing_up.png'
  ]);

  SurfaceEmgGameDatabase database = SurfaceEmgGameDatabase();
  await database.initialize();

  runApp(MyApp(SessionDataModel(database)));
}

class MyApp extends StatelessWidget {
  final SessionDataModel _sessionData;

  MyApp(this._sessionData);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionDataModel>.value(
        value: _sessionData,
        child: MaterialApp(
          title: 'Surface EMG Game',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
//      home: MainMenuPage(title: 'Test Game'),
          home: SelectUserPage(),
        ));
  }
}
