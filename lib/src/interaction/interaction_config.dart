import "package:flutter/animation.dart";
import "package:flutter/foundation.dart";

/// The configuration for the interaction the user has with a [GraphViewport].
@immutable
class InteractionConfig {
  /// The default value for [minFlingVelocity] when no value is supplied to the constructor.
  static const double kDefaultMinFlingVelocity = 50.0;

  /// Constructs an interction config from the given [minFlingVelocity] and [cameraEdgeMoveConfig].
  const InteractionConfig({
    this.minFlingVelocity = kDefaultMinFlingVelocity,
    this.cameraEdgeMoveConfig = const CameraEdgeMoveConfig(),
  });

  /// The minimum velocity a scale end gesture must have in order to start a fling animation.
  ///
  /// Defaults to [kDefaultMinFlingVelocity].
  final double minFlingVelocity;

  /// {@macro camera_edge_move_config}
  final CameraEdgeMoveConfig cameraEdgeMoveConfig;

  @override
  bool operator ==(covariant InteractionConfig other) {
    return minFlingVelocity == other.minFlingVelocity && cameraEdgeMoveConfig == other.cameraEdgeMoveConfig;
  }

  @override
  int get hashCode => Object.hash(minFlingVelocity, cameraEdgeMoveConfig);
}

/// {@template camera_edge_move_config}
/// The configuration for the camera move animation when dragging a node near the edge of the screen.
/// {@endtemplate}
@immutable
class CameraEdgeMoveConfig {
  /// The default value for [speed] when no value is supplied to the constructor.
  static const double kDefaultSpeed = 15;

  /// The default value for [rimDistanceThreshold] when no value is supplied to the constructor.
  static const double kDefaultRimDistanceThreshold = 60;

  /// The default value for [minDragDelta] when no value is supplied to the constructor.
  static const double kDefaultMinDragDelta = 5;

  /// The default value for [buildUpCurve] when no value is supplied to the constructor.
  static const Curve kDefaultBuildUpCurve = Curves.linear;

  /// The default value for [buildUpDuration] when no value is supplied to the constructor.
  static const Duration kDefaultBuildUpDuration = Duration(milliseconds: 750);

  /// Constructs a camera edge move configuration.
  const CameraEdgeMoveConfig({
    this.speed = kDefaultSpeed,
    this.rimDistanceThreshold = kDefaultRimDistanceThreshold,
    this.minDragDelta = kDefaultMinDragDelta,
    this.buildUpCurve = kDefaultBuildUpCurve,
    this.buildUpDuration = kDefaultBuildUpDuration,
  });

  /// The speed at which the camera should be moving.
  ///
  /// Defaults to [kDefaultSpeed].
  final double speed;

  /// The maximum distance from the viewport rim the pointer can have for the animation to play.
  ///
  /// Defaults to [kDefaultRimDistanceThreshold].
  final double rimDistanceThreshold;

  /// The minimum distance the pointer must have traveled for the animation to start.
  ///
  /// Defaults to [kDefaultMinDragDelta].
  final double minDragDelta;

  /// The animation curve that is used for a duration of [buildUpDuration] to reach full [speed].
  ///
  /// Defaults to [kDefaultBuildUpCurve].
  final Curve buildUpCurve;

  /// The duration that the [buildUpCurve] is applied until the animation reaches full [speed].
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
