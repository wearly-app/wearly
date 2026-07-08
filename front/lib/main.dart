import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/app.dart';
import 'package:front/features/user/closet/services/closet_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  ClosetService.instance.initializeDemoData();
  runApp(const WearlyApp());
}