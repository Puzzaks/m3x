// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elements.dart';

/// Represents a selectable item in [OptionPickerBottomSheet] or [OptionPickerDialog].
class OptionPickerItem<T> {
  final T value;
  final String title;
  final String subtitle;
  final IconData? icon;

  const OptionPickerItem({
    required this.value,
    required this.title,
    this.subtitle = '',
    this.icon,
  });
}

/// Draggable Material 3 modal bottom sheet option picker with a 40x4 drag handle
/// pill and a segmented [Cards.cardGroup] of radio-check rows.
///
/// Extracted from `PTK`'s stat and graph bottom-sheet pickers (`server_editor.dart`).
class OptionPickerBottomSheet<T> extends StatelessWidget {
  final String title;
  final List<OptionPickerItem<T>> options;
  final T? currentValue;
  final ValueChanged<T> onSelected;
  final ScrollController? scrollController;

  const OptionPickerBottomSheet({
    super.key,
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onSelected,
    this.scrollController,
  });

  /// Displays the modal bottom sheet and returns the selected option's value
  /// (or `null` if dismissed without selection).
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<OptionPickerItem<T>> options,
    T? currentValue,
    ValueChanged<T>? onSelected,
    double initialChildSize = 0.6,
    double minChildSize = 0.35,
    double maxChildSize = 0.92,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (_, scrollCtrl) => OptionPickerBottomSheet<T>(
          title: title,
          options: options,
          currentValue: currentValue,
          scrollController: scrollCtrl,
          onSelected: (value) {
            onSelected?.call(value);
            Navigator.of(sheetCtx).pop(value);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cards = Cards(context: context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Flexible(
          child: ListView(
            controller: scrollController,
            shrinkWrap: scrollController == null,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              cards.cardGroup(
                options.map((opt) {
                  final bool isSelected = opt.value == currentValue;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onSelected(opt.value);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          if (opt.icon != null) ...[
                            Icon(
                              opt.icon,
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                if (opt.subtitle.isNotEmpty)
                                  Text(
                                    opt.subtitle,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// AlertDialog option picker containing a scrollable [Cards.cardGroup] of
/// [CardContents.halfTap] items.
///
/// Used across `PTK`, `geminilocal`, `the2k48`, and `ggscanus` for language
/// and conference selection dialogs.
class OptionPickerDialog<T> extends StatelessWidget {
  final String title;
  final List<OptionPickerItem<T>> options;
  final T? currentValue;
  final ValueChanged<T> onSelected;

  const OptionPickerDialog({
    super.key,
    required this.title,
    required this.options,
    this.currentValue,
    required this.onSelected,
  });

  /// Displays the option picker dialog and returns the selected value.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<OptionPickerItem<T>> options,
    T? currentValue,
    ValueChanged<T>? onSelected,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => OptionPickerDialog<T>(
        title: title,
        options: options,
        currentValue: currentValue,
        onSelected: (value) {
          onSelected?.call(value);
          Navigator.of(dialogContext).pop(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = Cards(context: context);
    return AlertDialog(
      contentPadding: const EdgeInsets.only(top: 10, bottom: 15),
      titlePadding: const EdgeInsets.only(top: 20, right: 20, left: 20),
      title: Text(title),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: cards.cardGroup(
            options.map((opt) {
              return CardContents.halfTap(
                title: opt.title,
                subtitle: opt.subtitle,
                selected: currentValue != null && opt.value == currentValue,
                action: () => onSelected(opt.value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// AlertDialog with a rounded 20px [TextField], adjacent save [IconButton],
/// and an optional [Cards.cardGroup] of quick-pick suggestions below.
///
/// Extracted from `geminilocal` (prompt naming / model tokens) and `ggscanus`
/// (terminal name / printer IP address dialogs).
class TextInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String? hintText;
  final String initialValue;
  final TextInputType keyboardType;
  final List<OptionPickerItem<String>> suggestions;
  final ValueChanged<String> onSave;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.labelText,
    this.hintText,
    this.initialValue = '',
    this.keyboardType = TextInputType.text,
    this.suggestions = const [],
    required this.onSave,
  });

  /// Shows the text input dialog and returns the saved string (or `null` if
  /// dismissed).
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String labelText,
    String? hintText,
    String initialValue = '',
    TextInputType keyboardType = TextInputType.text,
    List<OptionPickerItem<String>> suggestions = const [],
    ValueChanged<String>? onSave,
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => TextInputDialog(
        title: title,
        labelText: labelText,
        hintText: hintText,
        initialValue: initialValue,
        keyboardType: keyboardType,
        suggestions: suggestions,
        onSave: (val) {
          onSave?.call(val);
          Navigator.of(dialogContext).pop(val);
        },
      ),
    );
  }

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    widget.onSave(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cards = Cards(context: context);
    return AlertDialog(
      contentPadding: const EdgeInsets.all(20),
      titlePadding: const EdgeInsets.only(top: 20, right: 20, left: 20),
      title: Text(widget.title),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: widget.keyboardType,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: widget.labelText,
                        hintText: widget.hintText,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: IconButton(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_rounded),
                    ),
                  ),
                ],
              ),
              if (widget.suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                cards.cardGroup(
                  widget.suggestions.map((suggestion) {
                    return CardContents.halfTap(
                      title: suggestion.title,
                      subtitle: suggestion.subtitle,
                      action: () {
                        _controller.text = suggestion.value;
                        _submit();
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
