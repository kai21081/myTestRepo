import 'dart:math';
import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gameplayground/components/bird_controller.dart';
import 'package:gameplayground/components/column_obstacle_controller.dart';
import 'package:gameplayground/components/repeating_background_controller.dart';
import 'package:gameplayground/components/target_controller.dart';
import 'package:gameplayground/models/Session.dart';
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/screens/main_menu.dart';
import 'package:provider/provider.dart';

class FlappyGame extends Game with HasWidgetsOverlay {
  Size _screenSize;
  double _tileSize;
  TargetController _targetController;
  BirdController _birdController;
  ColumnObstacleController _columnObstacleController;
  RepeatingBackgroundController _skyBackgroundController;
  RepeatingBackgroundController _grassBackgroundController;
  BuildContext _context;

  int _currentScore;
  int _highScore = 0;
  int _gameStartMillisecondsSinceEpoch;
  bool _isGameOver = false;

  final String gameOverMenuOverlayName = 'game_over_menu';
  final String currentScoreOverlayName = 'current_score';

  FlappyGame(this._context) {
    _initialize();
  }

  Size get screenSize => _screenSize;

  void _restartGame() {
    removeWidgetOverlay(gameOverMenuOverlayName);
    _initialize();
    _isGameOver = false;
  }

  @override
  void render(Canvas canvas) {
    Rect bgRect = Rect.fromLTWH(0, 0, _screenSize.width, _screenSize.height);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff576574);
    canvas.drawRect(bgRect, bgPaint);

    _skyBackgroundController.render(canvas);
    _columnObstacleController.render(canvas);
    _grassBackgroundController.render(canvas);
    _targetController.render(canvas);
    _birdController.render(canvas);
  }

  @override
  void resize(Size size) {
    _screenSize = size;
    _tileSize = _screenSize.width / 9;
    super.resize(size);

    _skyBackgroundController.resizeScreen(size);
    _grassBackgroundController.resizeScreen(size);
    _birdController.resizeScreen(size, _tileSize);
    _columnObstacleController.resizeScreen(size);
    _targetController.resizeScreen(size);
  }

  @override
  void update(double time) {
    if (_isGameOver) {
      return;
    }

    _skyBackgroundController.update(time);
    _grassBackgroundController.update(time);
    _birdController.update(time);
    _columnObstacleController.update(time);
    _targetController.update(time);

    if (_birdController.isBirdOnGround() ||
        _columnObstacleController
            .isCollidingWithObstacle(_birdController.getBirdPosition())) {
      int gameEndMillisecondsSinceEpoch = DateTime
          .now()
          .millisecondsSinceEpoch;

      _birdController.killBird();
      _isGameOver = true;
      _highScore = max(_highScore, _currentScore);
      print(
          Provider
              .of<SessionDataModel>(_context, listen: false)
              .currentUserId);
      _showGameOverMenu();

      _addGameDataToDatabase(
          _gameStartMillisecondsSinceEpoch, gameEndMillisecondsSinceEpoch,
          _currentScore);
    }

    int birdCollisionCount =
    _targetController.removeTargetsWithCollisionAndCalculateCount(
        _birdController.getBirdPosition());
    _currentScore += birdCollisionCount;
    _updateScoreCounter();
  }

  void _addGameDataToDatabase(int startTimestamp, int endTimestamp, int score) {
    // TODO: Actually store activation count, app version, and sensor data path.
    GameplayData gameplayData =
    GameplayData(startTimestamp, endTimestamp, score, 0, '', '');
    Provider.of<SessionDataModel>(_context, listen: false)
        .handleGameplayData(gameplayData);
  }

  void _showGameOverMenu() {
    addWidgetOverlay(
        gameOverMenuOverlayName,
        Center(
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
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FloatingActionButton.extended(
                label: Text('Restart'),
                heroTag: 'restart_game',
                onPressed: () => _restartGame(),
              ),
              SizedBox(height: 20),
              FloatingActionButton.extended(
                label: Text('Main Menu'),
                heroTag: 'main_menu_button',
                onPressed: () {
                  Navigator.push(this._context,
                      MaterialPageRoute(builder: (context) => MainMenuPage()));
                },
              )
            ],
          ),
        ));
  }

  void _initialize() async {
    _targetController = TargetController(
        0.5,
        'targets/cherry.png',
        Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        0.2,
        0.2,
        0.1,
        0.5);
    _birdController = BirdController();
    _columnObstacleController = ColumnObstacleController(
        0.5,
        'obstacles/column.png',
        Rect.fromLTWH(0.35, 0.1, 0.3, 0.9),
        0.4,
        0.7,
        0.6,
        0.8);
    _skyBackgroundController = RepeatingBackgroundController(
        'backgrounds/sky.png', 0.5, Rect.fromLTWH(0.0, 0.0, 1.0, 1.0));
    _grassBackgroundController = RepeatingBackgroundController(
        'backgrounds/ground.png', 0.5, Rect.fromLTWH(0.0, 0.9, 1.0, 0.1));

    resize(await Flame.util.initialDimensions());

    _targetController.initialize(_screenSize);
    _birdController.initialize(_screenSize, _tileSize);
    _columnObstacleController.initialize(_screenSize);
    _skyBackgroundController.initialize(screenSize);
    _grassBackgroundController.initialize(screenSize);

    // Add temporary score counter.
    _currentScore = 0;
    _gameStartMillisecondsSinceEpoch = DateTime
        .now()
        .millisecondsSinceEpoch;
    _updateScoreCounter();
  }

  void _updateScoreCounter() {
    removeWidgetOverlay(currentScoreOverlayName);
    addWidgetOverlay(
        currentScoreOverlayName,
        Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score: $_currentScore',
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 54,
                          decoration: TextDecoration.none)),
                  Text('High Score: $_highScore',
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          decoration: TextDecoration.none)),
                ])));
  }

  void onTapDown(TapDownDetails details) {
    _birdController.onTapDown();
  }
}
