import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({this.height = 50, this.compact = false, super.key});
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'FinControl',
    image: true,
    child: Container(
      height: height + 20,
      constraints: BoxConstraints(maxWidth: compact ? 180 : 300),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F17320D),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'images/logo.png',
        height: height,
        fit: BoxFit.contain,
      ),
    ),
  );
}
