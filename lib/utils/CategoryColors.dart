// lib/utils/category_colors.dart
import 'package:flutter/material.dart';

class CategoryColors {
  static const Map<String, Color> categoryColors = {
    // Home & Property
    'Electrician': Color(0xFFFF6B6B),
    'Plumber': Color(0xFF4D96FF),
    'Carpenter': Color(0xFF6BCB77),
    'Mason': Color(0xFF9B59B6),
    'Painter': Color(0xFFFFD93D),
    'Tile Worker': Color(0xFFE67E22),
    'Gypsum/Ceiling': Color(0xFF3498DB),
    'Interior Designer': Color(0xFFE91E63),
    'Furniture Assembly': Color(0xFF795548),
    'Handyman': Color(0xFF607D8B),
    'Locksmith': Color(0xFFFF5722),
    'Pest Control': Color(0xFF4CAF50),
    'House Cleaner': Color(0xFF00BCD4),
    'Deep Cleaning': Color(0xFF2196F3),
    'Water Tank Cleaning': Color(0xFF009688),
    'Gardener': Color(0xFF8BC34A),
    'Landscaping': Color(0xFF2E7D32),
    'Pool Maintenance': Color(0xFF00BCD4),

    // Automotive
    'Car Mechanic': Color(0xFFE74C3C),
    'Bike Mechanic': Color(0xFFE67E22),
    'EV Technician': Color(0xFF2ECC71),
    'Battery Replacement': Color(0xFF3498DB),
    'Tire/Puncture': Color(0xFFE74C3C),
    'Oil Change': Color(0xFFF39C12),
    'Car Wash/Detailing': Color(0xFF1ABC9C),
    'AC Repair': Color(0xFF00B4D8),
    'Auto Electrician': Color(0xFF6C5CE7),
    'Towing': Color(0xFFE74C3C),
    'Roadside Assistance': Color(0xFFF39C12),
    'Vehicle Inspection': Color(0xFF2ECC71),
    'Mobile Mechanic': Color(0xFFE67E22),

    // Energy & Utilities
    'Solar Installation': Color(0xFFFFB300),
    'Solar Maintenance': Color(0xFFFFB300),
    'Inverter Technician': Color(0xFF2196F3),
    'Battery Technician': Color(0xFF4CAF50),
    'Generator Technician': Color(0xFF9E9E9E),
    'Electrical Inspection': Color(0xFFFF6B6B),
    'Energy Audit': Color(0xFF00BCD4),
    'UPS Technician': Color(0xFF2196F3),
    'Smart Meter Installation': Color(0xFF009688),
    'EV Charging Installation': Color(0xFF4CAF50),

    // Technology
    'Mobile Repair': Color(0xFFFF6B6B),
    'Laptop Repair': Color(0xFF4D96FF),
    'Computer Repair': Color(0xFF6C5CE7),
    'Software Installation': Color(0xFF00BCD4),
    'Wi-Fi/Networking': Color(0xFF2196F3),
    'CCTV Installation': Color(0xFFE74C3C),
    'Printer Repair': Color(0xFF9B59B6),
    'Data Recovery': Color(0xFFFF6B6B),
    'Website Development': Color(0xFF6C5CE7),
    'IT Support': Color(0xFF4D96FF),
    'Smart Home Installation': Color(0xFF00BCD4),
    'Cybersecurity Services': Color(0xFF2ECC71),

    // Business & Office
    'Office Cleaning': Color(0xFF00BCD4),
    'HVAC Maintenance': Color(0xFF4CAF50),
    'Electrical Maintenance': Color(0xFFFF6B6B),
    'Security Systems': Color(0xFF2196F3),
    'Office Moving': Color(0xFFE67E22),
    'Facility Management': Color(0xFF9E9E9E),
    'Equipment Maintenance': Color(0xFF607D8B),
    'Event Support': Color(0xFFE91E63),

    // Delivery & Logistics
    'Local Delivery': Color(0xFF4CAF50),
    'Furniture Transport': Color(0xFF795548),
    'Moving Services': Color(0xFFE67E22),
    'Courier': Color(0xFF2196F3),
    'Pickup/Drop-off': Color(0xFF00BCD4),
    'Truck/Van Rental': Color(0xFF607D8B),
    'Driver Services': Color(0xFF3498DB),
    'Warehouse Services': Color(0xFF9E9E9E),

    // Personal Services
    'Barber': Color(0xFFE91E63),
    'Makeup Artist': Color(0xFFE91E63),
    'Beautician': Color(0xFFFF6B6B),
    'Salon at Home': Color(0xFFE91E63),
    'Tailor': Color(0xFF9C27B0),
    'Laundry': Color(0xFF4D96FF),
    'Personal Trainer': Color(0xFFFF6B6B),
    'Photographer': Color(0xFF9E9E9E),
    'Event Services': Color(0xFFE91E63),

    // Education
    'Home Tutor': Color(0xFFFFB300),
    'Online Tutor': Color(0xFF2196F3),
    'Language Teacher': Color(0xFFFF6B6B),
    'Coding Teacher': Color(0xFF4D96FF),
    'Music Teacher': Color(0xFFE91E63),
    'Exam Preparation': Color(0xFFFFB300),
    'Assignment Assistance': Color(0xFF4CAF50),
    'Professional Training': Color(0xFF6C5CE7),

    // Events
    'Videographer': Color(0xFFE74C3C),
    'Decorator': Color(0xFFE91E63),
    'Caterer': Color(0xFFFF6B6B),
    'DJ': Color(0xFF6C5CE7),
    'Event Planner': Color(0xFFE91E63),
    'Wedding Services': Color(0xFFFF6B6B),
    'Sound/Light Rental': Color(0xFF9E9E9E),
    'Furniture/Tent Rental': Color(0xFF795548),

    // Agriculture
    'Farm Equipment Repair': Color(0xFF4CAF50),
    'Tractor Mechanic': Color(0xFFE67E22),
    'Irrigation Technician': Color(0xFF00BCD4),
    'Solar Pump Technician': Color(0xFFFFB300),
    'Agricultural Machinery': Color(0xFF4CAF50),
    'Tree Services': Color(0xFF2E7D32),
    'Water Pump Repair': Color(0xFF2196F3),
    'Farm Labor': Color(0xFF8BC34A),
    'Livestock Services': Color(0xFF795548),

    // Industrial
    'Industrial Electrician': Color(0xFFFF6B6B),
    'Welding': Color(0xFFE74C3C),
    'Machine Repair': Color(0xFF607D8B),
    'Fabrication': Color(0xFF9E9E9E),
    'Mechanical Maintenance': Color(0xFF607D8B),
    'Industrial Plumbing': Color(0xFF4D96FF),
    'Safety Inspection': Color(0xFFFFB300),
    'Equipment Technicians': Color(0xFF607D8B),

    // Security
    'Security Guard': Color(0xFF2196F3),

    // Emergency
    'Emergency Electrician': Color(0xFFFF0000),
    'Emergency Plumber': Color(0xFFFF0000),
    '24/7 Locksmith': Color(0xFFFF0000),
    'Emergency Towing': Color(0xFFFF0000),
  };

  static Color getColor(String categoryName, {Color defaultColor = const Color(0xFF6C63FF)}) {
    return categoryColors[categoryName] ?? defaultColor;
  }

  static Color getColorForCategory(Map<String, dynamic> category, {Color defaultColor = const Color(0xFF6C63FF)}) {
    final name = category['name'] as String?;
    if (name == null) return defaultColor;
    return getColor(name, defaultColor: defaultColor);
  }
}