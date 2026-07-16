package com.wearly.auth.client;

import com.wearly.auth.dto.response.KakaoUserResponse;
import com.wearly.auth.exception.AuthErrorCode;
import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import jakarta.security.auth.message.AuthException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;

@Component
public class KakaoApiClient {

    private static final String KAKAO_USER_INFO_URI = "https://kapi.kakao.com/v2/user/me";
    private static final String BEARER_PREFIX = "Bearer ";

    private final WebClient webClient;

    public KakaoApiClient(WebClient.Builder webClientBuilder) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 3000)
                .responseTimeout(Duration.ofSeconds(5))
                .doOnConnected(connection -> connection
                        .addHandlerLast(new ReadTimeoutHandler(5))
                        .addHandlerLast(new WriteTimeoutHandler(5)));

        this.webClient = webClientBuilder
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .build();
    }

    @org.springframework.beans.factory.annotation.Value("${kakao.rest-api-key:4495f583b16b0ff643477b99638d9e3a}")
    private String restApiKey;

    public KakaoUserResponse getUserInfo(String kakaoAccessToken) {
        return webClient.get()
                .uri(KAKAO_USER_INFO_URI)
                .header(HttpHeaders.AUTHORIZATION, BEARER_PREFIX + kakaoAccessToken)
                .retrieve()
                .onStatus(
                        HttpStatusCode::is4xxClientError,
                        response -> Mono.error(new AuthException(String.valueOf(AuthErrorCode.INVALID_KAKAO_ACCESS_TOKEN)))
                )
                .onStatus(
                        HttpStatusCode::is5xxServerError,
                        response -> Mono.error(new AuthException(String.valueOf(AuthErrorCode.KAKAO_SERVER_ERROR)))
                )
                .bodyToMono(KakaoUserResponse.class)
                .block();
    }

    public String getAccessTokenFromAuthCode(String authCode, String redirectUri, String codeVerifier) {
        org.springframework.util.MultiValueMap<String, String> formData = new org.springframework.util.LinkedMultiValueMap<>();
        formData.add("grant_type", "authorization_code");
        formData.add("client_id", restApiKey);
        formData.add("redirect_uri", redirectUri);
        formData.add("code", authCode);
        if (codeVerifier != null && !codeVerifier.isEmpty()) {
            formData.add("code_verifier", codeVerifier);
        }

        com.wearly.auth.dto.response.KakaoTokenResponse response = webClient.post()
                .uri("https://kauth.kakao.com/oauth/token")
                .header(HttpHeaders.CONTENT_TYPE, "application/x-www-form-urlencoded;charset=utf-8")
                .body(org.springframework.web.reactive.function.BodyInserters.fromFormData(formData))
                .retrieve()
                .onStatus(
                        HttpStatusCode::is4xxClientError,
                        clientResponse -> Mono.error(new AuthException(String.valueOf(AuthErrorCode.INVALID_KAKAO_ACCESS_TOKEN)))
                )
                .onStatus(
                        HttpStatusCode::is5xxServerError,
                        clientResponse -> Mono.error(new AuthException(String.valueOf(AuthErrorCode.KAKAO_SERVER_ERROR)))
                )
                .bodyToMono(com.wearly.auth.dto.response.KakaoTokenResponse.class)
                .block();

        if (response == null || response.getAccessToken() == null) {
            throw new RuntimeException("Failed to exchange Kakao authorization code for access token.");
        }

        return response.getAccessToken();
    }
}
