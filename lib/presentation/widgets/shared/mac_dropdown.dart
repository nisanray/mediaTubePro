import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MacDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const MacDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.unfold_more,
            size: 16,
            color: AppColors.onSurfaceVariant,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w400,
          ),
          dropdownColor: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
