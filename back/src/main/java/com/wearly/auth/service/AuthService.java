package com.wearly.auth.service;

import com.wearly.auth.client.KakaoApiClient;
import com.wearly.auth.dto.request.KakaoLoginRequest;
import com.wearly.auth.dto.response.KakaoUserResponse;
import com.wearly.auth.dto.response.TokenResponse;
import com.wearly.domain.user.entity.User;
import com.wearly.domain.user.repository.UserRepository;
import com.wearly.global.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final KakaoApiClient kakaoApiClient;
    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional
    public TokenResponse loginWithKakao(KakaoLoginRequest request) {
        String kakaoAccessToken;
        if (request.getAuthCode() != null && !request.getAuthCode().isEmpty()) {
            kakaoAccessToken = kakaoApiClient.getAccessTokenFromAuthCode(
                    request.getAuthCode(),
                    request.getRedirectUri(),
                    request.getCodeVerifier()
            );
        } else {
            kakaoAccessToken = request.getAccessToken();
        }

        KakaoUserResponse kakaoUser = kakaoApiClient.getUserInfo(kakaoAccessToken);

        User user = userRepository.findByKakaoId(kakaoUser.getKakaoId())
                .orElseGet(() -> createUser(kakaoUser));

        String accessToken = jwtTokenProvider.createAccessToken(user.getId());

        return new TokenResponse(accessToken);
    }

    private User createUser(KakaoUserResponse kakaoUser) {
        User user = User.create(
                kakaoUser.getKakaoId(),
                kakaoUser.getNickname(),
                kakaoUser.getEmail()
        );

        return userRepository.save(user);
    }
}
