package com.wearly.auth.exception;

import com.wearly.global.exception.ErrorCode;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum AuthErrorCode implements ErrorCode {

    UNAUTHENTICATED_ACCESS(HttpStatus.UNAUTHORIZED, "인증이 필요합니다."),
    INVALID_ACCESS_TOKEN(HttpStatus.UNAUTHORIZED, "유효하지 않은 액세스 토큰입니다."),
    ACCESS_TOKEN_EXPIRED(HttpStatus.UNAUTHORIZED, "만료된 액세스 토큰입니다."),
    INVALID_KAKAO_ACCESS_TOKEN(HttpStatus.UNAUTHORIZED, "유효하지 않은 카카오 액세스 토큰입니다."),
    KAKAO_SERVER_ERROR(HttpStatus.BAD_GATEWAY, "카카오 서버와 통신 중 오류가 발생했습니다.");

    private final HttpStatus httpStatus;
    private final String message;
}
