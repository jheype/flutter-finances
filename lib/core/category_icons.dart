import 'package:flutter/material.dart';

/// chave -> ícone (Material Icons)
const Map<String, IconData> kCategoryIconByKey = {
  'groceries': Icons.local_grocery_store_rounded,
  'transport': Icons.directions_bus_filled_rounded,
  'food': Icons.restaurant_rounded,
  'bills': Icons.receipt_long_rounded,
  'home': Icons.home_rounded,
  'health': Icons.volunteer_activism_rounded,
  'education': Icons.school_rounded,
  'fun': Icons.celebration_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'travel': Icons.flight_takeoff_rounded,
  'pets': Icons.pets_rounded,
  'subscriptions': Icons.subscriptions_rounded,
  'car': Icons.directions_car_filled_rounded,
  'salary': Icons.payments_rounded,
  'freelance': Icons.work_history_rounded,
  'invest': Icons.trending_up_rounded,
  'other': Icons.category_rounded,
};

IconData iconFromKey(String? key) => kCategoryIconByKey[key] ?? Icons.category_rounded;

/// lista para o picker
const List<String> kCategoryIconKeys = [
  'groceries',
  'transport',
  'food',
  'bills',
  'home',
  'health',
  'education',
  'fun',
  'shopping',
  'travel',
  'pets',
  'subscriptions',
  'car',
  'salary',
  'freelance',
  'invest',
  'other',
];
