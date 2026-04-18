import "package:flutter/material.dart";
import "package:flutter/services.dart" show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import "package:interactive_graph_view/interactive_graph_view.dart"
    show LineStyle, SolidLineStyle, DashedLineStyle, DottedLineStyle;

import "../main.dart" show ExampleEdge;

class EdgePropertiesPanel extends StatefulWidget {
  const EdgePropertiesPanel({
    super.key,
    required this.edge,
    required this.onDeleteEdge,
    required this.onShowTextChanged,
    required this.onTextChanged,
    required this.onTextBackgroundColorChanged,
    required this.onLineColorChanged,
    required this.onLineStyleChanged,
    required this.onOverrideArrowStyleChanged,
    required this.onArrowChanged,
  });

  final ExampleEdge edge;
  final void Function() onDeleteEdge;
  final void Function(bool showText) onShowTextChanged;
  final void Function(String text) onTextChanged;
  final void Function(Color? textBackgroundColor) onTextBackgroundColorChanged;
  final void Function(Color? lineColor) onLineColorChanged;
  final void Function(LineStyle? lineStyle) onLineStyleChanged;
  final void Function(bool overrideArrowStyle) onOverrideArrowStyleChanged;
  final void Function(double arrowWidth, double arrowLength) onArrowChanged;

  @override
  State<EdgePropertiesPanel> createState() => _EdgePropertiesPanelState();
}

class _EdgePropertiesPanelState extends State<EdgePropertiesPanel> {
  late final TextEditingController _textTextController;
  late final TextEditingController _arrowWidthTextController;
  late final TextEditingController _arrowLengthTextController;

  late bool _showText;
  late Color? _textBackgroundColor;
  late Color? _lineColor;
  late LineStyle? _lineStyle;
  late bool _overrideArrowStyle;

  @override
  void initState() {
    super.initState();

    _textTextController = TextEditingController(text: widget.edge.text);
    _arrowWidthTextController = TextEditingController(
      text: widget.edge.arrowWidth.toInt().toString(),
    );
    _arrowLengthTextController = TextEditingController(
      text: widget.edge.arrowLength.toInt().toString(),
    );

    _showText = widget.edge.showText;
    _textBackgroundColor = widget.edge.textBackgroundColor;
    _lineColor = widget.edge.lineColor;
    _lineStyle = widget.edge.lineStyle;
    _overrideArrowStyle = widget.edge.overrideArrowStyle;
  }

  @override
  void didUpdateWidget(covariant EdgePropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_textTextController.text != widget.edge.text) {
      _textTextController.text = widget.edge.text;
    }
    final String newArrowWidthText = widget.edge.arrowWidth.toInt().toString();
    if (_arrowWidthTextController.text != newArrowWidthText) {
      _arrowWidthTextController.text = newArrowWidthText;
    }
    final String newArrowLengthText = widget.edge.arrowLength.toInt().toString();
    if (_arrowLengthTextController.text != newArrowLengthText) {
      _arrowLengthTextController.text = newArrowLengthText;
    }

    _showText = widget.edge.showText;
    _textBackgroundColor = widget.edge.textBackgroundColor;
    _lineColor = widget.edge.lineColor;
    _lineStyle = widget.edge.lineStyle;
    _overrideArrowStyle = widget.edge.overrideArrowStyle;
  }

  void _onTapShowText() {
    setState(() => _showText = !_showText);
    widget.onShowTextChanged(_showText);
  }

  void _onTextChanged(String value) {
    widget.onTextChanged(value);
  }

  void _onTextBackgroundColorChanged(Color? value) {
    setState(() => _textBackgroundColor = value);
    widget.onTextBackgroundColorChanged(value);
  }

  void _onLineColorChanged(Color? value) {
    setState(() => _lineColor = value);
    widget.onLineColorChanged(value);
  }

  void _onLineStyleChanged(LineStyle? value) {
    setState(() => _lineStyle = value);
    widget.onLineStyleChanged(value);
  }

  void _onTapOverrideArrowStyle() {
    setState(() => _overrideArrowStyle = !_overrideArrowStyle);
    widget.onOverrideArrowStyleChanged(_overrideArrowStyle);
  }

  void _onArrowChanged() {
    final double newArrowWidth = double.tryParse(_arrowWidthTextController.text) ?? 10;
    final double newArrowLength = double.tryParse(_arrowLengthTextController.text) ?? 10;

    widget.onArrowChanged(newArrowWidth, newArrowLength);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          children: [
            Text("Edge ${widget.edge.id}"),
            Spacer(),
            IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => widget.onDeleteEdge(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _onTapShowText,
          child: Row(
            children: [
              Checkbox(
                value: _showText,
                onChanged: (value) => _onTapShowText(),
              ),
              Expanded(child: Text("Show Text")),
            ],
          ),
        ),
        TextField(
          controller: _textTextController,
          onChanged: _onTextChanged,
          enabled: _showText,
          decoration: InputDecoration(labelText: "Text"),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Color>(
          initialValue: _textBackgroundColor,
          onChanged: _showText ? _onTextBackgroundColorChanged : null,
          decoration: InputDecoration(labelText: "Text Background Color"),
          items: [
            DropdownMenuItem(child: Text("None (use fallback)")),
            DropdownMenuItem(
              value: Colors.transparent,
              child: Text("Transparent"),
            ),
            ...[Colors.black, Colors.white, ...Colors.primaries].map(
              (color) => DropdownMenuItem(
                value: color,
                child: Container(
                  color: color,
                  child: Text("#${color.toARGB32().toRadixString(16)}"),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Color>(
          initialValue: _lineColor,
          onChanged: _onLineColorChanged,
          decoration: InputDecoration(labelText: "Line Color"),
          items: [
            DropdownMenuItem(child: Text("None (use fallback)")),
            ...[Colors.black, Colors.white, ...Colors.primaries].map(
              (color) => DropdownMenuItem(
                value: color,
                child: Container(
                  color: color,
                  child: Text("#${color.toARGB32().toRadixString(16)}"),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<LineStyle>(
          initialValue: _lineStyle,
          onChanged: _onLineStyleChanged,
          decoration: InputDecoration(labelText: "Line Style"),
          items: [
            DropdownMenuItem(child: Text("None (use fallback)")),
            DropdownMenuItem(
              value: SolidLineStyle(thickness: 2),
              child: Text("Solid"),
            ),
            DropdownMenuItem(
              value: DashedLineStyle(thickness: 2, dashSize: 8, gapSize: 12),
              child: Text("Dashed"),
            ),
            DropdownMenuItem(
              value: DottedLineStyle(thickness: 2),
              child: Text("Dotted"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            GestureDetector(
              onTap: _onTapOverrideArrowStyle,
              child: Row(
                children: [
                  Checkbox(
                    value: _overrideArrowStyle,
                    onChanged: (value) => _onTapOverrideArrowStyle(),
                  ),
                  Expanded(child: Text("Override arrow style")),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _arrowWidthTextController,
                    onChanged: (value) => _onArrowChanged(),
                    enabled: _overrideArrowStyle,
                    decoration: InputDecoration(label: Text("Arrow width")),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _arrowLengthTextController,
                    onChanged: (value) => _onArrowChanged(),
                    enabled: _overrideArrowStyle,
                    decoration: InputDecoration(label: Text("Arrow length")),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
