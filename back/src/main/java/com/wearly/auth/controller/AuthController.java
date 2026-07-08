package com.wearly.auth.controller;

import com.wearly.auth.dto.request.KakaoLoginRequest;
import com.wearly.auth.dto.response.TokenResponse;
import com.wearly.auth.service.AuthService;
import com.wearly.global.security.JwtTokenProvider;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final JwtTokenProvider jwtTokenProvider;

    @PostMapping("/kakao")
    public ResponseEntity<TokenResponse> loginWithKakao(
            @Valid @RequestBody KakaoLoginRequest request
    ) {
        TokenResponse response = authService.loginWithKakao(request);

        return ResponseEntity.ok(response);
    }


    @PostMapping("/test-token")
    public ResponseEntity<TokenResponse> createTestToken(
            @RequestParam Long userId
    ) {
        String accessToken = jwtTokenProvider.createAccessToken(userId);

        return ResponseEntity.ok(new TokenResponse(accessToken));
    }
}
