import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ManualParameterInput extends StatefulWidget {
  final String label;
  final double currentValue;
  final double min;
  final double max;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;
  final IconData? icon;
  final int decimals;

  const ManualParameterInput({
    Key? key,
    required this.label,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
    this.icon,
    this.decimals = 1,
  }) : super(key: key);

  @override
  State<ManualParameterInput> createState() => _ManualParameterInputState();
}

class _ManualParameterInputState extends State<ManualParameterInput> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue.toStringAsFixed(widget.decimals),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ManualParameterInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.currentValue != oldWidget.currentValue) {
      _controller.text = widget.currentValue.toStringAsFixed(widget.decimals);
    }
  }

  void _showInputDialog() {
    _controller.text = widget.currentValue.toStringAsFixed(widget.decimals);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: widget.color.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.color, size: 24),
              const SizedBox(width: 12),
            ],
            Text(
              'Enter ${widget.label}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Virgülü noktaya çevir
                  final text = newValue.text.replaceAll(',', '.');
                  return TextEditingValue(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ],
              style: TextStyle(
                color: widget.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                suffixText: widget.unit,
                suffixStyle: TextStyle(
                  color: widget.color.withOpacity(0.7),
                  fontSize: 20,
                ),
                hintText: 'Enter value',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.color.withOpacity(0.5)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.color, width: 2),
                ),
              ),
              onSubmitted: (value) => _submitValue(value),
            ),
            const SizedBox(height: 16),
            Text(
              'Range: ${widget.min.toStringAsFixed(widget.decimals)} - ${widget.max.toStringAsFixed(widget.decimals)} ${widget.unit}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => _submitValue(_controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: AppTheme.darkBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _submitValue(String value) {
    // Virgülü noktaya çevir
    final normalizedValue = value.replaceAll(',', '.');
    final parsed = double.tryParse(normalizedValue);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showInputDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.color, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              '${widget.currentValue.toStringAsFixed(widget.decimals)} ${widget.unit}',
              style: TextStyle(
                color: widget.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit,
              color: widget.color.withOpacity(0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
