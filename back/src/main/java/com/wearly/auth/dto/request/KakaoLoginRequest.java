package com.wearly.auth.dto.request;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class KakaoLoginRequest {

    private String accessToken;
    private String authCode;
    private String redirectUri;
    private String codeVerifier;
}
