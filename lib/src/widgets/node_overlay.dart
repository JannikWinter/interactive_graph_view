import "package:flutter/widgets.dart";

class NodeOverlayConfig {
  const NodeOverlayConfig({
    this.alignmentInNode = Alignment.center,
    this.alignmentAroundAnchor = Alignment.center,
    this.offset = Offset.zero,
  });

  final Alignment alignmentInNode;
  final Alignment alignmentAroundAnchor;
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

class NodeOverlay extends NodeOverlayConfig {
  const NodeOverlay({
    super.alignmentInNode,
    super.alignmentAroundAnchor,
    super.offset,
    required this.child,
  });

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
