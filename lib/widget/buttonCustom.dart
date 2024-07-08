import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ButtomCustom extends StatefulWidget {
  final Function onPressed;
  final bool? isSplashScreen;
  final String title;
  final double textSize;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? width;
  final FocusNode? focusNode;

  const ButtomCustom({
    super.key,
    required this.onPressed,
    this.isSplashScreen,
    required this.title,
    required this.textSize,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.width,
    this.focusNode,
  });

  @override
  State<ButtomCustom> createState() => _ButtomCustomState();
}

class _ButtomCustomState extends State<ButtomCustom> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode ?? _focusNode,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      autofocus: true,
      child: GestureDetector(
        onTap: () => widget.onPressed(),
        child: Container(
          width: widget.width,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 45, vertical: 10),
          margin: widget.margin,
          decoration: BoxDecoration(
            color: _isFocused
                ? (widget.color ?? const Color.fromARGB(255, 192, 227, 255))
                    .withOpacity(0.7)
                : widget.color ??
                    (_isFocused
                        ? const Color.fromARGB(255, 192, 227, 255)
                            .withOpacity(0.7)
                        : Colors.white),
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(widget.borderRadius ?? 50),
              right: Radius.circular(widget.borderRadius ?? 50),
            ),
          ),
          child: Center(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: widget.textSize,
                fontWeight: FontWeight.bold,
                color: widget.isSplashScreen == null
                    ? Colors.white
                    : const Color(0xffEB6E2C),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
