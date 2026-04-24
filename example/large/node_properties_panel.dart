import "package:flutter/material.dart";
import "package:flutter/services.dart" show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;

import "../large.dart" show ExampleNode;

class NodePropertiesPanel extends StatefulWidget {
  const NodePropertiesPanel({
    super.key,
    required this.node,
    required this.onDeleteNode,
    required this.onTextChanged,
    required this.onBackgroundColorChanged,
    required this.onTextColorChanged,
    required this.onBorderRadiusChanged,
  });

  final ExampleNode node;
  final void Function() onDeleteNode;
  final void Function(String text) onTextChanged;
  final void Function(Color? backgroundColor) onBackgroundColorChanged;
  final void Function(Color? textColor) onTextColorChanged;
  final void Function(Radius? borderRadius) onBorderRadiusChanged;

  @override
  State<NodePropertiesPanel> createState() => _NodePropertiesPanelState();
}

class _NodePropertiesPanelState extends State<NodePropertiesPanel> {
  late final TextEditingController _textTextController;
  late final TextEditingController _borderRadiusTextController;

  late Color? _backgroundColor;
  late Color? _textColor;

  @override
  void initState() {
    super.initState();

    _textTextController = TextEditingController(text: widget.node.text);
    _borderRadiusTextController = TextEditingController(text: widget.node.borderRadius?.x.toInt().toString() ?? "");

    _backgroundColor = widget.node.backgroundColor;
    _textColor = widget.node.textColor;
  }

  @override
  void didUpdateWidget(covariant NodePropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_textTextController.text != widget.node.text) {
      _textTextController.text = widget.node.text;
    }
    final String newBorderRadiusText = widget.node.borderRadius?.x.toInt().toString() ?? "";
    if (_borderRadiusTextController.text != newBorderRadiusText) {
      _borderRadiusTextController.text = newBorderRadiusText;
    }

    _backgroundColor = widget.node.backgroundColor;
    _textColor = widget.node.textColor;
  }

  void _onTextTextChanged(String value) {
    widget.onTextChanged(value);
  }

  void _onBackgroundColorChanged(Color? value) {
    setState(() => _backgroundColor = value);
    widget.onBackgroundColorChanged(value);
  }

  void _onTextColorChanged(Color? value) {
    setState(() => _textColor = value);
    widget.onTextColorChanged(value);
  }

  void _onBorderRadiusChanged(String value) {
    final Radius? newBorderRadius;
    if (value.isNotEmpty) {
      newBorderRadius = Radius.circular(double.parse(value));
    } else {
      newBorderRadius = null;
    }
    widget.onBorderRadiusChanged(newBorderRadius);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          children: [
            Text("Node ${widget.node.id}"),
            Spacer(),
            IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => widget.onDeleteNode(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textTextController,
          onChanged: _onTextTextChanged,
          decoration: InputDecoration(labelText: "Text"),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Color>(
          initialValue: _backgroundColor,
          onChanged: _onBackgroundColorChanged,
          decoration: InputDecoration(labelText: "Background Color"),
          items: [
            DropdownMenuItem(child: Text("None (use fallback)")),
            ...[Colors.black, Colors.white, ...Colors.primaries].map(
              (color) => DropdownMenuItem(
                value: color,
                child: Container(
                  color: color,
                  child: Text(
                    "#${color.toARGB32().toRadixString(16)}",
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Color>(
          initialValue: _textColor,
          onChanged: _onTextColorChanged,
          decoration: InputDecoration(labelText: "Text Color"),
          items: [
            DropdownMenuItem(child: Text("None (use fallback)")),
            ...[Colors.black, Colors.white, ...Colors.primaries].map(
              (color) => DropdownMenuItem(
                value: color,
                child: Container(
                  color: color,
                  child: Text(
                    "#${color.toARGB32().toRadixString(16)}",
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _borderRadiusTextController,
          onChanged: _onBorderRadiusChanged,
          decoration: InputDecoration(labelText: "Border radius"),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
        ),
      ],
    );
  }
}
