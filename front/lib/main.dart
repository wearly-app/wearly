import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:front/config/app_config.dart';
import 'package:front/app.dart';
import 'package:front/features/user/closet/services/closet_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Web redirect check at the very entry point before routing strips the URL!
  if (kIsWeb) {
    final queryParams = Uri.base.queryParameters;
    if (queryParams.containsKey('code')) {
      final code = queryParams['code'];
      const storage = FlutterSecureStorage();
      await storage.write(key: 'wearly_redirect_code', value: code);
    }
  }

  // Initialize Kakao SDK
  await KakaoSdk.init(
    nativeAppKey: AppConfig.kakaoNativeAppKey,
    javaScriptAppKey: AppConfig.kakaoJavaScriptAppKey,
  );

  if (kDebugMode && !kIsWeb) {
    debugPrint('Kakao KeyHash: ${KakaoSdk.platformInfo.origin}');
  }

  if (AppConfig.useMockApi) {
    ClosetService.instance.initializeDemoData();
  }

  runApp(const WearlyApp());
}
