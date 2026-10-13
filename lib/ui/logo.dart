import 'package:flutter/material.dart';

class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key, this.size = 96});
  final double size;
  @override
  Widget build(BuildContext context) => Icon(Icons.precision_manufacturing,
      size: size, color: Theme.of(context).colorScheme.primary);
}
