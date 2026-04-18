import "package:flutter/widgets.dart";

class HorizontalOrVertical extends StatelessWidget {
  const HorizontalOrVertical({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    if (size.width >= size.height) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: primary),
          SizedBox(width: size.width / 5, child: secondary),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: primary),
          SizedBox(height: size.height / 3, child: secondary),
        ],
      );
    }
  }
}
