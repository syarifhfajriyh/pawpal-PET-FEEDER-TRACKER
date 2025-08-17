import 'package:flutter/material.dart';
import 'package:paw_ui/widgets/CarouselPicker.dart';

class InstantFeed extends StatefulWidget {
  /// UI-only: parent controls status messaging & loading spinner.
  final bool loading;
  final bool error;
  final String message;

  /// Portion sizes & default index (UI state for picker).
  final List<String> portionSizes;
  final int defaultPosition;

  /// Callbacks
  final ValueChanged<String>? onFeedNow;
  final ValueChanged<String>? onSelect;

  const InstantFeed({
    super.key,
    this.loading = false,
    this.error = false,
    this.message = "",
    this.portionSizes = const [
      "100g",
      "200g",
      "300g",
      "400g",
      "500g",
      "600g",
      "700g",
      "800g",
      "900g",
    ],
    this.defaultPosition = 3, // "400g"
    this.onFeedNow,
    this.onSelect,
  });

  @override
  State<InstantFeed> createState() => _InstantFeedState();
}

class _InstantFeedState extends State<InstantFeed> {
  late String _portionSize;

  @override
  void initState() {
    super.initState();
    final safeIndex = (widget.defaultPosition >= 0 &&
            widget.defaultPosition < widget.portionSizes.length)
        ? widget.defaultPosition
        : 0;
    _portionSize = widget.portionSizes[safeIndex];
  }

  void _selectedPortion(String v) {
    setState(() => _portionSize = v);
    widget.onSelect?.call(v);
  }

  void _handleFeedNow() {
    widget.onFeedNow?.call(_portionSize);
  }

  @override
  Widget build(BuildContext context) {
    final bodyMed = Theme.of(context).textTheme.bodyMedium;
    final bodyLg = Theme.of(context).textTheme.bodyLarge;

    final portionSizeView = Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Select feeding portion size:",
            style: TextStyle(
              color: bodyMed?.color,
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
            textAlign: TextAlign.center,
          ),
          Container(
            margin: const EdgeInsets.only(top: 16.0),
            child: CarouselPicker(
              values: widget.portionSizes,
              onSelect: _selectedPortion,
              defaultPosition: widget.defaultPosition,
            ),
          ),
        ],
      ),
    );

    final messageBar = Container(
      width: MediaQuery.of(context).size.width,
      height: 30.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        color: widget.error != true
            ? (widget.message.isNotEmpty
                ? Colors.green
                : (bodyMed?.color ?? Colors.black54).withOpacity(0.1))
            : Colors.red,
      ),
      child: Center(
        child: Text(
          widget.message,
          style: const TextStyle(
            color: Color(0xFFffffff),
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    final feedBtn = Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: widget.loading
          ? const Center(child: RefreshProgressIndicator())
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF0e2a47),
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0.5,
              ),
              onPressed: _handleFeedNow,
              child: const Text(
                'Feed Now',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                  letterSpacing: 0.4,
                ),
              ),
            ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [messageBar, portionSizeView, feedBtn],
    );
  }
}
