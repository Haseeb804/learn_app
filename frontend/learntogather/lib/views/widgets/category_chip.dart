import 'package:flutter/material.dart';
import '../../models/category_model.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryChip({
    Key? key,
    required this.category,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color? chipColor;
    if (category.color != null) {
      try {
        chipColor = Color(int.parse(category.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        chipColor = null;
      }
    }

    return FilterChip(
      label: Text(category.name),
      selected: isSelected,
      onSelected: (_) => onTap?.call(),
      backgroundColor: chipColor?.withOpacity(0.1),
      selectedColor: chipColor?.withOpacity(0.3),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}