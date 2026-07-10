class AppConfig {
  // Replace this with your actual Kakao Native App Key from the Kakao Developer Console
  static const String kakaoNativeAppKey = 'c7644a187c5f3bcbc5e1a7c3da8ec7d1';
  static const String kakaoJavaScriptAppKey = 'c68943dc1d19987fdc8be7cb594ba31d';

  // Base URL of the Spring Boot API backend.
  // - Use 'http://10.0.2.2:8080' for the Android emulator to connect to localhost on your PC.
  // - Use 'http://localhost:8080' for the iOS simulator or web browser.
  // - Use your local network IP (e.g. 'http://192.168.x.x:8080') for physical mobile devices.
  static const String apiBaseUrl = 'http://localhost:8080'; 
}
