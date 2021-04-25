import 'package:flame/flame.dart';

class AssetPaths {
  static final String imageCherry = 'targets/cherry.png';
  static final String imageColumn = 'obstacles/column.png';
  static final String imageBirdDead = 'birds/bird_dead.png';
  static final String imageBirdWingDown = 'birds/bird_wing_down.png';
  static final String imageBirdWingUp = 'birds/bird_wing_up.png';
  static final String imageSkyBackground = 'backgrounds/sky.png';
  static final String imageGroundBackground = 'backgrounds/ground.png';

  static final String musicBackgroundSong = 'background_music.mp3';
}

List<String> _getImageAssetPaths() {
  return <String>[
    AssetPaths.imageCherry,
    AssetPaths.imageColumn,
    AssetPaths.imageBirdDead,
    AssetPaths.imageBirdWingDown,
    AssetPaths.imageBirdWingUp,
    AssetPaths.imageSkyBackground,
    AssetPaths.imageGroundBackground
  ];
}

List<String> _getMusicAssetPaths() {
  return <String>[AssetPaths.musicBackgroundSong];
}

void loadAssets() {
  Flame.images.loadAll(_getImageAssetPaths());
  Flame.audio.disableLog();
  Flame.audio.loadAll(_getMusicAssetPaths());
}
