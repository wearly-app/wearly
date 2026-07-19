import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:front/config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:front/features/user/closet/models/recommendation_response.dart';

// Helper to generate a PKCE-compliant secure random code verifier
String _generateCodeVerifier() {
  final Random random = Random.secure();
  final List<int> values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64Url
      .encode(values)
      .replaceAll('=', '')
      .replaceAll('+', '-')
      .replaceAll('/', '_');
}

class UserModel {
  final int id;
  final String kakaoId;
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.kakaoId,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      kakaoId: json['kakaoId'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class ClothingItemsPage {
  final List<Map<String, dynamic>> content;
  final int page;
  final bool hasNext;

  const ClothingItemsPage({
    required this.content,
    required this.page,
    required this.hasNext,
  });

  factory ClothingItemsPage.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>? ?? const [];

    return ClothingItemsPage(
      content: content
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}

class OutfitItemsPage {
  final List<Map<String, dynamic>> content;
  final int page;
  final bool hasNext;

  const OutfitItemsPage({
    required this.content,
    required this.page,
    required this.hasNext,
  });

  factory OutfitItemsPage.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>? ?? const [];

    return OutfitItemsPage(
      content: content
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}

class ApiService {
  final _storage = const FlutterSecureStorage();
  static const String _jwtKey = 'wearly_jwt_token';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Log in using the Kakao SDK, then send the Kakao Access Token to our backend
  /// to receive and store a custom JWT token.
  Future<bool> loginWithKakao() async {
    try {
      String kakaoAccessToken;

      if (kIsWeb) {
        // 1. Web Flow: Generate code verifier and redirect URI for PKCE
        final String redirectUri = '${Uri.base.origin}/auth.html';
        final String codeVerifier = _generateCodeVerifier();

        // Save the code verifier to secure storage so we can retrieve it after redirect!
        await _storage.write(key: 'wearly_code_verifier', value: codeVerifier);
        print('Web redirect URI: $redirectUri');

        // This redirects the page, so execution will stop here as the page reloads.
        await AuthCodeClient.instance.authorize(
          redirectUri: redirectUri,
          codeVerifier: codeVerifier,
        );
        return false;
      } else {
        // Mobile Flow: Check if KakaoTalk is installed and try to log in.
        OAuthToken oauthToken;
        if (await isKakaoTalkInstalled()) {
          try {
            oauthToken = await UserApi.instance.loginWithKakaoTalk();
            print('Logged in successfully via KakaoTalk.');
          } catch (error) {
            print('Failed to login via KakaoTalk: $error');

            // If the login via KakaoTalk was cancelled by the user, don't fallback.
            if (error is PlatformException && error.code == 'CANCELED') {
              rethrow;
            }

            // Fallback to Kakao Account login
            oauthToken = await UserApi.instance.loginWithKakaoAccount();
            print('Logged in successfully via Kakao Account fallback.');
          }
        } else {
          oauthToken = await UserApi.instance.loginWithKakaoAccount();
          print('Logged in successfully via Kakao Account.');
        }
        kakaoAccessToken = oauthToken.accessToken;
      }

      // 3. Send the Kakao access token to our Spring Boot backend
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': kakaoAccessToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final String? serverJwt = body['accessToken'];

        if (serverJwt != null) {
          // 3. Save the backend JWT token to secure storage
          await _storage.write(key: _jwtKey, value: serverJwt);
          return true;
        }
      } else {
        print('Backend auth failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during Kakao Login flow: $e');
    }
    return false;
  }

  /// Handle OAuth redirect on web. Checks if the URL has a 'code' query parameter.
  /// If present, exchanges it for tokens, calls the backend, and returns true.
  Future<bool> handleWebRedirectIfAny() async {
    if (!kIsWeb) return false;

    // Retrieve redirect code from secure storage (saved in main.dart)
    final authCode = await _storage.read(key: 'wearly_redirect_code');
    if (authCode != null) {
      // Immediately delete to prevent double processing
      await _storage.delete(key: 'wearly_redirect_code');
      print('Processing redirect authorization code: $authCode');

      try {
        // Retrieve the code verifier stored before redirect
        final codeVerifier = await _storage.read(key: 'wearly_code_verifier');
        if (codeVerifier == null) {
          print('Error: stored code_verifier not found');
          return false;
        }

        final redirectUri = '${Uri.base.origin}/auth.html';
        print('Web exchanging token with redirectUri: $redirectUri');

        // Call backend directly with the Authorization Code, Redirect URI, and Code Verifier
        // (exchanging the code for a token is handled on the backend to avoid CORS restrictions on Web)
        final response = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/auth/kakao'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'authCode': authCode,
            'redirectUri': redirectUri,
            'codeVerifier': codeVerifier,
          }),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final String? serverJwt = body['accessToken'];

          if (serverJwt != null) {
            // Save server JWT and clear code verifier
            await _storage.write(key: _jwtKey, value: serverJwt);
            await _storage.delete(key: 'wearly_code_verifier');
            return true;
          }
        } else {
          print(
              'Backend redirect auth failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('Error handling Web redirect code: $e');
      } finally {
        // Clear code verifier in any case
        await _storage.delete(key: 'wearly_code_verifier');
      }
    }
    return false;
  }

  /// Get the currently logged-in user profile from our backend (/api/users/me)
  Future<UserModel?> getUserProfile() async {
    try {
      final token = await getJwtToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserModel.fromJson(data);
      } else {
        print('Failed to get user profile: ${response.statusCode}');
        // If unauthorized, token might be expired. Clean it up.
        if (response.statusCode == 401) {
          await logoutLocally();
        }
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  /// Log out from the backend and wipe the locally stored JWT token.
  Future<void> logout() async {
    try {
      final token = await getJwtToken();
      if (token != null) {
        // Send logout request to backend (stateless JWT, but good practice to notify)
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      print('Backend logout failed: $e. Proceeding with local logout.');
    } finally {
      await logoutLocally();
    }
  }

  /// Check if the user is already authenticated (has a token).
  /// Optionally verifies the token by calling the backend profile API.
  Future<bool> isAuthenticated() async {
    final token = await getJwtToken();
    if (token == null) return false;

    // Verify token validity by requesting profile
    final profile = await getUserProfile();
    return profile != null;
  }

  /// Retrieve the stored JWT token
  Future<String?> getJwtToken() async {
    return await _storage.read(key: _jwtKey);
  }

  /// Get real-time outfit recommendations for the authenticated user.
  Future<RecommendationApiResponse?> getRecommendations({
    required double latitude,
    required double longitude,
    required String style,
    int limit = 3,
  }) async {
    try {
      final token = await getJwtToken();
      if (token == null) {
        print('Recommendation request skipped: JWT token not found.');
        return null;
      }

      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/recommendations',
      ).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'style': style,
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return RecommendationApiResponse.fromJson(
          json as Map<String, dynamic>,
        );
      }

      print(
        'Recommendation request failed: '
        '${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Error requesting recommendations: $e');
    }
    return null;
  }

  /// Clear token locally
  Future<void> logoutLocally() async {
    await _storage.delete(key: _jwtKey);
    try {
      // Also logout from Kakao SDK session
      await UserApi.instance.logout();
    } catch (e) {
      print('Kakao SDK logout error: $e');
    }
  }

  /// Send clothing image to backend to remove background and extract metadata.
  Future<Map<String, dynamic>?> analyzeClothingImage(XFile imageFile) async {
    if (AppConfig.useMockApi) {
      print('Using Mock API for analyzeClothingImage');
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate network delay
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // UI development mock data
      return {
        'imageKey': 'mock/clothes/${imageFile.name}',
        'imageUrl': 'data:image/png;base64,$base64Image',
        'category': 'TOP', // 상의
        'colorH': 20, // #4A2F22 (Brown)
        'colorS': 36,
        'colorV': 29,
        'season': ['봄', '가을'],
        'style': 'CASUAL',
        'brand': 'No Brand',
        'material': '코튼 100%',
        'thickness': 2, // 3.0 slider
        'cloValue': 0.65,
      };
    }

    try {
      final token = await getJwtToken();
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/clothes/analyze');
      final request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Read bytes to support both Web and Mobile platforms
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      } else {
        print('Image analysis failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during image analysis API call: $e');
    }
    return null;
  }

  /// Create a new clothing item in the backend database.
  Future<Map<String, dynamic>?> createClothingItem(
      Map<String, dynamic> itemData) async {
    if (AppConfig.useMockApi) {
      print('Using Mock API for createClothingItem: $itemData');
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        ...itemData,
        'id': DateTime.now().millisecondsSinceEpoch,
        'imageUrl': null,
        'wearCount': 0,
        'lastWornAt': null,
      };
    }

    try {
      final token = await getJwtToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/clothes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(itemData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      } else {
        print(
            'Failed to create clothing item: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating clothing item: $e');
    }
    return null;
  }

  /// Load the current user's clothes from the backend database.
  Future<ClothingItemsPage?> getClothingItems({
    int page = 0,
    int size = 10,
  }) async {
    if (AppConfig.useMockApi) {
      return ClothingItemsPage(
        content: const [],
        page: page,
        hasNext: false,
      );
    }

    try {
      final token = await getJwtToken();
      if (token == null) return null;

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/clothes').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ClothingItemsPage.fromJson(data);
      }

      print(
          'Failed to load clothing items: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error loading clothing items: $e');
    }

    return null;
  }

  /// Soft-delete a clothing item owned by the current user.
  Future<bool> deleteClothingItem(String clothesId) async {
    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }

    try {
      final token = await getJwtToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/api/clothes/$clothesId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return true;
      }

      print(
        'Failed to delete clothing item: '
        '${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Error deleting clothing item: $e');
    }

    return false;
  }

  /// Create an outfit from clothes owned by the current user.
  Future<Map<String, dynamic>?> createOutfit({
    required String name,
    required String style,
    required List<int> clothesIds,
  }) async {
    final requestBody = {
      'name': name,
      'style': style,
      'clothesIds': clothesIds,
    };

    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'id': DateTime.now().millisecondsSinceEpoch,
        ...requestBody,
        'thumbnailUrl': null,
        'favorite': false,
        'clothes': const [],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }

    try {
      final token = await getJwtToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/outfits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }

      print(
        'Failed to create outfit: '
        '${response.statusCode} - ${utf8.decode(response.bodyBytes)}',
      );
    } catch (e) {
      print('Error creating outfit: $e');
    }

    return null;
  }

  /// Soft-delete an outfit owned by the current user.
  Future<bool> deleteOutfit(String outfitId) async {
    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }

    try {
      final token = await getJwtToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/api/outfits/$outfitId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return true;
      }

      print(
        'Failed to delete outfit: '
        '${response.statusCode} - ${utf8.decode(response.bodyBytes)}',
      );
    } catch (e) {
      print('Error deleting outfit: $e');
    }

    return false;
  }

  /// Load the current user's saved outfits.
  Future<OutfitItemsPage?> getOutfits({
    int page = 0,
    int size = 10,
  }) async {
    if (AppConfig.useMockApi) {
      return OutfitItemsPage(
        content: const [],
        page: page,
        hasNext: false,
      );
    }

    try {
      final token = await getJwtToken();
      if (token == null) return null;

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/outfits').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return OutfitItemsPage.fromJson(data);
      }

      print(
        'Failed to load outfits: '
        '${response.statusCode} - ${utf8.decode(response.bodyBytes)}',
      );
    } catch (e) {
      print('Error loading outfits: $e');
    }

    return null;
  }

  /// Record a saved outfit as worn today.
  Future<Map<String, dynamic>?> wearOutfit(String outfitId) async {
    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'historyId': DateTime.now().millisecondsSinceEpoch,
        'outfitId': int.tryParse(outfitId),
        'wornDate': DateTime.now().toIso8601String().substring(0, 10),
        'clothesIds': const [],
        'createdAt': DateTime.now().toIso8601String(),
      };
    }

    try {
      final token = await getJwtToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/outfits/$outfitId/wear'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }

      print(
        'Failed to record outfit wear: '
        '${response.statusCode} - ${utf8.decode(response.bodyBytes)}',
      );
    } catch (e) {
      print('Error recording outfit wear: $e');
    }

    return null;
  }
}
