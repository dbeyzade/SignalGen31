import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeonSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;
  final IconData? icon;

  const NeonSlider({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.color,
    required this.onChanged,
    this.icon,
  }) : super(key: key);

  @override
  State<NeonSlider> createState() => _NeonSliderState();
}

class _NeonSliderState extends State<NeonSlider> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6), // Reduced from 12
          padding: const EdgeInsets.all(12), // Reduced from 20
          decoration: BoxDecoration(
            color: AppTheme.cardBg.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withOpacity(0.3 + (_controller.value * 0.4)),
              width: 2,
            ),
            boxShadow: [
              if (_isActive)
                BoxShadow(
                  color: widget.color.withOpacity(0.3 + (_controller.value * 0.3)),
                  blurRadius: 15 + (_controller.value * 10),
                  spreadRadius: 2 + (_controller.value * 3),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13, // Reduced from 16
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.color.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.value.toStringAsFixed(1)} ${widget.unit}',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 13, // Reduced from 16
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Reduced from 12
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4, // Reduced from 6
                  activeTrackColor: widget.color,
                  inactiveTrackColor: widget.color.withOpacity(0.2),
                  thumbColor: widget.color,
                  overlayColor: widget.color.withOpacity(0.3),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10, // Reduced from 12
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20, // Reduced from 24
                  ),
                ),
                child: Slider(
                  value: widget.value,
                  min: widget.min,
                  max: widget.max,
                  divisions: widget.divisions,
                  onChanged: (value) {
                    widget.onChanged(value);
                  },
                  onChangeStart: (value) {
                    setState(() {
                      _isActive = true;
                      _controller.forward();
                    });
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      _isActive = false;
                      _controller.reverse();
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
