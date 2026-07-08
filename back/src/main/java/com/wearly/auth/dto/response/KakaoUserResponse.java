package com.wearly.auth.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;

@Getter
public class KakaoUserResponse {

    private Long id;

    private Properties properties;

    @JsonProperty("kakao_account")
    private KakaoAccount kakaoAccount;

    public String getKakaoId() {
        return String.valueOf(id);
    }

    public String getNickname() {
        if (properties != null) {
            return properties.getNickname();
        }

        return null;
    }

    public String getEmail() {
        if (kakaoAccount != null) {
            return kakaoAccount.getEmail();
        }

        return null;
    }
}
