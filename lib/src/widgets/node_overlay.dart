import "package:flutter/widgets.dart";

/// The **internally used** typed for [NodeOverlay]s.
///
/// If you want to define an overlay on a [NodeWidget] use [NodeOverlay].
abstract class NodeOverlayConfig {
  /// {@template node_overlay_config.default_alignment_in_node}
  /// The default value for [alignmentInNode] when it is not supplied to the constructor.
  /// {@endtemplate}
  static const kDefaultAlignmentInNode = Alignment.center;

  /// {@template node_overlay_config.default_alignment_around_anchor}
  /// The default value for [alignmentAroundAnchor] when it is not supplied to the constructor.
  /// {@endtemplate}
  static const kDefaultAlignmentAroundAnchor = Alignment.center;

  /// {@template node_overlay_config.default_offset}
  /// The default value for [offset] when it is not supplied to the constructor.
  /// {@endtemplate}
  static const kDefaultOffset = Offset.zero;

  const NodeOverlayConfig({
    this.alignmentInNode = Alignment.center,
    this.alignmentAroundAnchor = Alignment.center,
    this.offset = Offset.zero,
  });

  /// The anchor alignment of this overlay in relation to the node's size.
  ///
  /// For configuring the alignment of the overlay's child around the anchor in relation to the child's size,
  /// use [alignmentAroundAnchor].
  ///
  /// Defaults to [kDefaultAlignmentInNode].
  final Alignment alignmentInNode;

  /// The alignment of this overlay's child around the anchor in relation to the child's size.
  ///
  /// For configuring the alignment of the anchor itself in relation to the node's size, use [alignmentInNode].
  ///
  /// Defaults to [kDefaultAlignmentAroundAnchor].
  final Alignment alignmentAroundAnchor;

  /// The offset of this overlay's child after [alignmentInNode] and [alignmentAroundAnchor] were applied.
  ///
  /// Defaults to [kDefaultOffset].
  final Offset offset;

  @override
  bool operator ==(Object other) {
    if (other is! NodeOverlay) return false;
    return alignmentInNode == other.alignmentInNode &&
        alignmentAroundAnchor == other.alignmentAroundAnchor &&
        offset == other.offset;
  }

  @override
  int get hashCode => Object.hash(
    alignmentInNode,
    alignmentAroundAnchor,
    offset,
  );
}

/// A widget for configuring an overlay on a [NodeWidget].
class NodeOverlay extends NodeOverlayConfig {
  /// {@macro node_overlay_config.default_alignment_in_node}
  static const kDefaultAlignmentInNode = NodeOverlayConfig.kDefaultAlignmentInNode;

  /// {@macro node_overlay_config.default_alignment_around_anchor}
  static const kDefaultAlignmentAroundAnchor = NodeOverlayConfig.kDefaultAlignmentAroundAnchor;

  /// {@macro node_overlay_config.default_offset}
  static const kDefaultOffset = NodeOverlayConfig.kDefaultOffset;

  /// Constructs a node overlay.
  const NodeOverlay({
    super.alignmentInNode,
    super.alignmentAroundAnchor,
    super.offset,
    required this.child,
  });

  /// The child that will be placed according to [alignmentInNode], [alignmentAroundAnchor] and [offset].
  final Widget child;

  @override
  bool operator ==(Object other) {
    if (other is! NodeOverlay) return false;
    return super == other && child == other.child;
  }

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    child,
  );
}
