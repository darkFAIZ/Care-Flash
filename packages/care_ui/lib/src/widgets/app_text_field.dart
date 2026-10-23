import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// The one text field used across both apps: filled, radius 12, min height 48,
/// label above the field and a reveal button for passwords.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.obscureText = false,
    this.required = false,
    this.labelInside = false,
    this.enabled = true,
    this.readOnly = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? initialValue;
  final bool obscureText;
  final bool required;

  /// When true the label sits inside the field as a floating label instead of
  /// above it, which is what the Care-Merchant forms use.
  final bool labelInside;
  final bool enabled;
  final bool readOnly;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final translate = AppLocalizations.maybeOf(context)?.t;
    String tr(String value) => translate?.call(value) ?? value;
    final Widget? revealButton = widget.obscureText
        ? IconButton(
            // Icon-only button, so it keeps a full 48px target and a label.
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: _obscured ? tr('Show password') : tr('Hide password'),
            onPressed: () => setState(() => _obscured = !_obscured),
            icon: Icon(
              _obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.labelInside)
          Text.rich(
            TextSpan(
              text: tr(widget.label),
              children: [
                if (widget.required)
                  TextSpan(text: ' *', style: TextStyle(color: scheme.error)),
              ],
            ),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        if (!widget.labelInside) const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          obscureText: _obscured,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator == null
              ? null
              : (value) {
                  final message = widget.validator!(value);
                  return message == null ? null : tr(message);
                },
          decoration: InputDecoration(
            labelText: widget.labelInside ? tr(widget.label) : null,
            hintText: widget.hint == null ? null : tr(widget.hint!),
            helperText:
                widget.helperText == null ? null : tr(widget.helperText!),
            errorText: widget.errorText == null ? null : tr(widget.errorText!),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 22),
            suffixIcon: widget.suffix ?? revealButton,
          ),
        ),
      ],
    );
  }
}
