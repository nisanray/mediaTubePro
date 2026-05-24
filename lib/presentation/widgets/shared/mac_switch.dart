import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';

class MacSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MacSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Scaling it down to match the compact desktop aesthetic
    return Transform.scale(
      scale: 0.8,
      child: CupertinoSwitch(
        value: value,
        activeColor: AppColors.success,
        trackColor: AppColors.surfaceContainerHighest,
        onChanged: onChanged,
      ),
    );
  }
}
