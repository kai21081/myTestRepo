import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:gameplayground/components/horizontally_moving_sprite.dart';

class TargetController {
  List<HorizontallyMovingSprite> _targets;
  Random _randomNumberGenerator;
  double _velocityInScreenWidthsPerSecond;
  Size _screenSize;
  double _spawnFrequencyHertz = 100;
  double _timeSinceLastSpawn = 0.0;
  bool _isInitialized = false;
  int _totalTime = 0;
  String _targetImageName;
  Rect _targetRegionForCollision;
  Map<int, List<double>> _spawnMap;
  double _targetWidthAsScreenWidthFraction;
  double _targetHeightAsScreenWidthFraction;
  File _spawnConfig;
  double _spawnMinHeightAsScreenHeightFraction;
  double _spawnMaxHeightAsScreenHeightFraction;

  TargetController(
      double velocityInScreenWidthsPerSecond,
      String targetImageName,
      Rect targetRegionForCollision,
      double targetWidthAsScreenWidthFraction,
      double targetHeightAsScreenWidthFraction,
      double spawnMinHeightAsScreenHeightFraction,
      double spawnMaxHeightAsScreenHeightFraction,
      double spawnFrequencyHertz,
      //String levelPath
      ) {
    _targets = List<HorizontallyMovingSprite>();
    _velocityInScreenWidthsPerSecond = velocityInScreenWidthsPerSecond;
    _targetImageName = targetImageName;
    _targetRegionForCollision = targetRegionForCollision;
    _targetWidthAsScreenWidthFraction = targetWidthAsScreenWidthFraction;
    _targetHeightAsScreenWidthFraction = targetHeightAsScreenWidthFraction;
    _spawnMinHeightAsScreenHeightFraction =
        spawnMinHeightAsScreenHeightFraction;
    _spawnMaxHeightAsScreenHeightFraction =
        spawnMaxHeightAsScreenHeightFraction;
    _spawnFrequencyHertz = spawnFrequencyHertz;
    _parseSpawnMapFromFile('assets/levels/level1.txt'); //levelPath
  }

  // Removes targets with collision and returns collision count (i.e. points
  // scored).
  int removeTargetsWithCollisionAndCalculateCount(Rect birdPosition) {
    int preCollisionTargetCount = _targets.length;
    _targets.removeWhere((HorizontallyMovingSprite target) =>
        target.isCollidingWithRect(birdPosition));
    int postCollisionTargetCount = _targets.length;

    return preCollisionTargetCount - postCollisionTargetCount;
  }

  void render(Canvas canvas) {
    _targets
        .forEach((HorizontallyMovingSprite target) => target.render(canvas));
  }

  void update(double time) {
    if (!_isInitialized) {
      return;
    }
    _totalTime += 1;
    _targets.forEach((HorizontallyMovingSprite target) => target.update(time));
    _timeSinceLastSpawn += time;

    if (_spawnMap != null && _spawnMap.containsKey(_totalTime)) {
      _spawnMap[_totalTime].forEach((location) {
        _spawnTargetAtLocation(location);
      });
    }
  }

  void _spawnTargetAtLocation(double position) {
    double targetHeight =
        _targetHeightAsScreenWidthFraction * _screenSize.width;
    double targetWidth = _targetWidthAsScreenWidthFraction * _screenSize.width;
    double yTopPositionForSpawn = position * _screenSize.height;

    Rect initialPosition = Rect.fromLTWH(
        _screenSize.width, yTopPositionForSpawn, targetWidth, targetHeight);
    _targets.add(HorizontallyMovingSprite(_targetImageName, initialPosition,
        _calculateVelocityInScreenUnitsPerSecond(), _targetRegionForCollision));
  }

  double _calculateVelocityInScreenUnitsPerSecond() {
    // Negative because the targets should move right to left and screen origin
    // is top left.
    return -_velocityInScreenWidthsPerSecond * _screenSize.width;
  }

  void initialize(Size screenSize) {
    _randomNumberGenerator = Random();
    resizeScreen(screenSize);
    _isInitialized = true;
  }

  void resizeScreen(Size size) {
    if (_isInitialized) {
      double scaleX = size.width / _screenSize.width;
      double scaleY = size.height / _screenSize.height;
      _targets.forEach((HorizontallyMovingSprite target) =>
          target.applyTransformToPosition(0.0, 0.0, scaleX, scaleY));
      _targets.forEach((HorizontallyMovingSprite target) =>
          target.updateHorizontalVelocity(
              _calculateVelocityInScreenUnitsPerSecond()));
    }

    _screenSize = size;
  }

  void _parseSpawnMapFromFile(String path) {
    Future<String> level = rootBundle.loadString(path);
    Future.delayed(Duration(milliseconds: 10),() => level.then((text) {
       _spawnMap = _getMap(text);
    }));
  }

  HashMap<int, List<double>> _getMap(String spawns) {
    Map<int, List<double>> spawnMap = new HashMap<int, List<double>>();
    List<String> spawnList = spawns.split('\n');
    for (int i = 0; i < spawnList.length; i++) {
      List<String> singleSpawns = spawnList[i].split(' ');
      List<double> spawnLoci = new List<double>();
      for (int j = 1; j < singleSpawns.length; j++) {
        spawnLoci.add(double.parse(singleSpawns[j]));
      }
      if (singleSpawns[0] != '') {
        spawnMap.putIfAbsent(int.parse(singleSpawns[0]), () => spawnLoci);
      }
    }
    return spawnMap;
  }
}
