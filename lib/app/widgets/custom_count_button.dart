import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 为学习流程提供带范围校验的自定义数量入口。
class CustomCountButton extends StatelessWidget {
  const CustomCountButton({
    super.key,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.unit,
    required this.dialogTitle,
    required this.fieldLabel,
    required this.enabled,
    required this.onChanged,
  }) : assert(minimum > 0),
       assert(maximum >= minimum),
       assert(value >= minimum && value <= maximum);

  final int value;
  final int minimum;
  final int maximum;
  final String unit;
  final String dialogTitle;
  final String fieldLabel;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: enabled ? () => _showPicker(context) : null,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text('自定义（当前 $value$unit）'),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => _CustomCountDialog(
        initialValue: value,
        minimum: minimum,
        maximum: maximum,
        title: dialogTitle,
        fieldLabel: fieldLabel,
        unit: unit,
      ),
    );
    if (selected != null && context.mounted) {
      onChanged(selected);
    }
  }
}

final class _CustomCountDialog extends StatefulWidget {
  const _CustomCountDialog({
    required this.initialValue,
    required this.minimum,
    required this.maximum,
    required this.title,
    required this.fieldLabel,
    required this.unit,
  });

  final int initialValue;
  final int minimum;
  final int maximum;
  final String title;
  final String fieldLabel;
  final String unit;

  @override
  State<_CustomCountDialog> createState() => _CustomCountDialogState();
}

final class _CustomCountDialogState extends State<_CustomCountDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialValue}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey('custom-count-input'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: widget.maximum.toString().length,
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.fieldLabel,
          helperText: '范围 ${widget.minimum}-${widget.maximum}${widget.unit}',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  void _submit() {
    final value = int.tryParse(_controller.text);
    if (value == null || value < widget.minimum || value > widget.maximum) {
      setState(() {
        _errorText = '请输入 ${widget.minimum}-${widget.maximum} 之间的整数';
      });
      return;
    }
    Navigator.pop(context, value);
  }
}
