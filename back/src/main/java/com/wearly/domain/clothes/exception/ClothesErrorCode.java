package com.wearly.domain.clothes.exception;

import com.wearly.global.exception.ErrorCode;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum ClothesErrorCode implements ErrorCode {

    CLOTHES_NOT_FOUND(HttpStatus.NOT_FOUND, "존재하지 않는 의류입니다.");

    private final HttpStatus httpStatus;
    private final String message;
}
