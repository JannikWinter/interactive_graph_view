import "package:flutter/animation.dart";
import "package:flutter/foundation.dart";

@immutable
class InteractionConfig {
  static const double kDefaultMinFlingVelocity = 50.0;

  const InteractionConfig({
    this.minFlingVelocity = kDefaultMinFlingVelocity,
    this.cameraEdgeMoveConfig = const CameraEdgeMoveConfig(),
  });

  final double minFlingVelocity;
  final CameraEdgeMoveConfig cameraEdgeMoveConfig;

  @override
  bool operator ==(covariant InteractionConfig other) {
    return minFlingVelocity == other.minFlingVelocity && cameraEdgeMoveConfig == other.cameraEdgeMoveConfig;
  }

  @override
  int get hashCode => Object.hash(minFlingVelocity, cameraEdgeMoveConfig);
}

@immutable
class CameraEdgeMoveConfig {
  static const double kDefaultSpeed = 15;
  static const double kDefaultRimDistanceThreshold = 60;
  static const double kDefaultMinDragDelta = 5;
  static const Curve kDefaultBuildUpCurve = Curves.linear;
  static const Duration kDefaultBuildUpDuration = Duration(milliseconds: 750);

  const CameraEdgeMoveConfig({
    this.speed = kDefaultSpeed,
    this.rimDistanceThreshold = kDefaultRimDistanceThreshold,
    this.minDragDelta = kDefaultMinDragDelta,
    this.buildUpCurve = kDefaultBuildUpCurve,
    this.buildUpDuration = kDefaultBuildUpDuration,
  });

  final double speed;
  final double rimDistanceThreshold;
  final double minDragDelta;
  final Curve buildUpCurve;
  final Duration buildUpDuration;

  @override
  bool operator ==(covariant CameraEdgeMoveConfig other) {
    return speed == other.speed &&
        rimDistanceThreshold == other.rimDistanceThreshold &&
        minDragDelta == other.minDragDelta &&
        buildUpCurve == other.buildUpCurve &&
        buildUpDuration == other.buildUpDuration;
  }

  @override
  int get hashCode => Object.hash(
    speed,
    rimDistanceThreshold,
    minDragDelta,
    buildUpCurve,
    buildUpDuration,
  );
}
