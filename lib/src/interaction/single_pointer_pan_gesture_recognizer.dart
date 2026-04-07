import "package:flutter/gestures.dart" show PanGestureRecognizer, PointerDownEvent, GestureDisposition;

class SinglePointerPanGestureRecognizer extends PanGestureRecognizer {
  SinglePointerPanGestureRecognizer({super.debugOwner, super.allowedButtonsFilter, super.supportedDevices});

  int _pointerCount = 0;

  @override
  void addPointer(PointerDownEvent event) {
    _pointerCount++;
    if (_pointerCount > 1) {
      // Adding more than one pointer rejects the gesture
      stopTrackingPointer(event.pointer);
      resolve(GestureDisposition.rejected);
    } else {
      super.addPointer(event);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointerCount = 0;
    super.didStopTrackingLastPointer(pointer);
  }
}
