import 'package:flutter/material.dart';

class CarouselPicker extends StatefulWidget {
  final List<String> values;
  final ValueChanged<String> onSelect;
  final int defaultPosition;

  const CarouselPicker({
    super.key,
    required this.values,
    required this.onSelect,
    required this.defaultPosition,
  });

  @override
  State<CarouselPicker> createState() => _CarouselPickerState();
}

class _CarouselPickerState extends State<CarouselPicker> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    final start = (widget.defaultPosition >= 0 &&
            widget.defaultPosition < widget.values.length)
        ? widget.defaultPosition
        : 0;
    _current = start;
    _controller = PageController(
      viewportFraction: 0.35, // show neighbors like a carousel
      initialPage: start,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int idx) {
    if (_current == idx) return;
    setState(() => _current = idx);
    widget.onSelect(widget.values[idx]);
  }

  @override
  Widget build(BuildContext context) {
    final bodyMed = Theme.of(context).textTheme.bodyMedium;
    final bodyLg = Theme.of(context).textTheme.bodyLarge;

    final bg = bodyMed?.color?.withOpacity(0.1);
    final activeColor = bodyLg?.color;
    final passiveColor = bodyMed?.color?.withOpacity(0.5);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 50.0,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: PageView.builder(
          controller: _controller,
          onPageChanged: _onPageChanged,
          scrollDirection: Axis.horizontal,
          itemCount: widget.values.length,
          padEnds: false,
          itemBuilder: (context, index) {
            final isActive = index == _current;
            return AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: isActive ? 15.0 : 14.0,
                fontWeight: FontWeight.w700,
                color: isActive ? activeColor : passiveColor,
              ),
              child: Center(child: Text(widget.values[index])),
            );
          },
        ),
      ),
    );
  }
}
