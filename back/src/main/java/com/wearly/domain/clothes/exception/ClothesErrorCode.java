package com.wearly.domain.clothes.exception;

import com.wearly.global.exception.ErrorCode;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum ClothesErrorCode implements ErrorCode {

    CLOTHES_NOT_FOUND(HttpStatus.NOT_FOUND, "존재하지 않는 의류입니다."),
    INVALID_CLOTHES_IMAGE(HttpStatus.BAD_REQUEST, "지원하지 않거나 올바르지 않은 이미지입니다."),
    REMBG_SERVICE_ERROR(HttpStatus.BAD_GATEWAY, "이미지 배경 제거 서비스 호출에 실패했습니다.");

    private final HttpStatus httpStatus;
    private final String message;
}
