package com.wearly.auth.client;

import com.wearly.auth.dto.response.KakaoUserResponse;
import com.wearly.auth.exception.AuthErrorCode;
import com.wearly.auth.exception.AuthException;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

@Component
public class KakaoApiClient {

    private static final String KAKAO_USER_INFO_URI = "https://kapi.kakao.com/v2/user/me";
    private static final String BEARER_PREFIX = "Bearer ";

    private final WebClient webClient;

    public KakaoApiClient(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.build();
    }

    public KakaoUserResponse getUserInfo(String kakaoAccessToken) {
        return webClient.get()
                .uri(KAKAO_USER_INFO_URI)
                .header(HttpHeaders.AUTHORIZATION, BEARER_PREFIX + kakaoAccessToken)
                .retrieve()
                .onStatus(
                        status -> status.is4xxClientError() || status.is5xxServerError(),
                        response -> {
                            throw new AuthException(AuthErrorCode.INVALID_KAKAO_ACCESS_TOKEN);
                        }
                )
                .bodyToMono(KakaoUserResponse.class)
                .block();
    }
}