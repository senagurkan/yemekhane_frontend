import 'package:flutter/material.dart';

Map<String, IconData> categoryIcons = {
  'çorba': Icons.soup_kitchen,
  'pilav': Icons.rice_bowl,
  'makarna': Icons.dinner_dining,
  'et': Icons.kebab_dining,
  'tavuk': Icons.egg,
  'salata': Icons.eco,
  'tatlı': Icons.cake,
  'default': Icons.restaurant,
};

IconData getCategoryIcon(String menuItem) {
  String itemLower = menuItem.toLowerCase();
  for (var category in categoryIcons.keys) {
    if (itemLower.contains(category)) {
      return categoryIcons[category]!;
    }
  }
  return categoryIcons['default']!;
}
