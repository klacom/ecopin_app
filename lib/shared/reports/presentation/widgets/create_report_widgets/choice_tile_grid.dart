import 'package:flutter/material.dart';

class ChoiceTileOption {
  const ChoiceTileOption(this.key, this.label, [this.icon]);
  final String key;
  final String label;
  final IconData? icon;
}

/// A grid of equal outlined tiles for picking one option: two columns on
/// ordinary widths, one when text is enlarged or the space is narrow. The
/// chosen tile gets a tinted fill, a primary outline and a check, so it is
/// never marked by color alone.
class ChoiceTileGrid extends StatelessWidget {
  const ChoiceTileGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });
  final List<ChoiceTileOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final single =
            constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(14) > 18.2;
        final width = single
            ? constraints.maxWidth
            : (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              SizedBox(
                width: width,
                child: _Tile(
                  option: option,
                  selected: selected == option.key,
                  onTap: () => onSelected(option.key),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final ChoiceTileOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? const Color(0xFF82B6FF) : scheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? accent.withValues(alpha: .12) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? accent
                : (theme.dividerTheme.color ?? scheme.outlineVariant),
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // The chosen tile swaps its glyph for a check, so the state
                  // is not color alone and the label keeps its width.
                  if (option.icon != null || selected) ...[
                    Icon(
                      selected ? Icons.check_circle : option.icon,
                      size: 18,
                      color: selected ? accent : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      option.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: selected ? accent : scheme.onSurface,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
