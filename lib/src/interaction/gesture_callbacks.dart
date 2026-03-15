import "drag_details.dart";
import "scale_details.dart";
import "tap_details.dart";

/// Callback for handling a TapDown gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportTapDownCallback = void Function(GraphViewportTapDownDetails details);

/// Callback for handling a Tap gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportTapCallback = void Function();

/// Callback for handling a DoubleTap gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportDoubleTapCallback = void Function();

/// Callback for handling a LongPress gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportLongPressCallback = void Function();

/// Callback for handling a DragDown gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportDragDownCallback = void Function(GraphViewportDragDownDetails details);

/// Callback for handling a DragStart gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportDragStartCallback = void Function(GraphViewportDragStartDetails details);

/// Callback for handling a DragUpdate gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportDragUpdateCallback = void Function(GraphViewportDragUpdateDetails details);

/// Callback for handling a DragEnd gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportDragEndCallback = void Function(GraphViewportDragEndDetails details);

/// Callback for handling a DragCancel gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportDragCancelCallback = void Function();

/// Callback for handling a ScaleStart gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportScaleStartCallback = void Function(GraphViewportScaleStartDetails details);

/// Callback for handling a ScaleUpdate gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportScaleUpdateCallback = void Function(GraphViewportScaleUpdateDetails details);

/// Callback for handling a ScaleEnd gesture that happened inside a [GraphViewport].
typedef GestureGraphViewportScaleEndCallback = void Function(GraphViewportScaleEndDetails details);
