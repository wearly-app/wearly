import 'dart:typed_data';
import 'package:flutter/material.dart';

class ClothingItem {
  final String id;
  String name;
  String category;
  String brand;
  final Uint8List? imageBytes;
  final String? assetPath;
  final String? imageUrl;
  final Color fallbackColor;
  final IconData fallbackIcon;

  // New fields for smart closet features
  List<String> seasons; // ['봄', '여름', '가을', '겨울']
  List<String> situation; // 스타일 카테고리 복수 선택 (예: ['캐주얼', '미니멀'])
  int thickness; // 1: 얇음, 2: 보통, 3: 두꺼움
  String colorHex; // '#FFFFFF' 형태
  DateTime? lastWornDate; // 마지막 착용 날짜
  int wearCount; // 착용 횟수
  int styleLevel; // 꾸밈 정도 (1~5)
  String? material; // 소재 (예: 면 100%)
  double? clo; // 단열 지수 (CLO)

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    this.imageBytes,
    this.assetPath,
    this.imageUrl,
    required this.fallbackColor,
    required this.fallbackIcon,
    required this.seasons,
    required this.situation,
    required this.thickness,
    required this.colorHex,
    this.lastWornDate,
    this.wearCount = 0,
    required this.styleLevel,
    this.material,
    this.clo,
  });
}

class CanvasItem {
  final String id;
  final ClothingItem clothing;
  Offset position;
  double scale;
  bool isFlipped;

  CanvasItem({
    required this.id,
    required this.clothing,
    required this.position,
    this.scale = 1.0,
    this.isFlipped = false,
  });
}

class SavedOutfit {
  final String id;
  final String title;
  String category;
  final List<ClothingItem> items;
  final DateTime createdAt;

  SavedOutfit({
    required this.id,
    required this.title,
    required this.category,
    required this.items,
    required this.createdAt,
  });
}

class WornRecord {
  final DateTime date;
  final SavedOutfit outfit;
  final String weather;
  final int temp;

  WornRecord({
    required this.date,
    required this.outfit,
    required this.weather,
    required this.temp,
  });
}
