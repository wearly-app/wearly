package com.wearly.domain.outfit.exception;

import com.wearly.global.exception.ErrorCode;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum OutfitErrorCode implements ErrorCode {

    OUTFIT_NOT_FOUND(HttpStatus.NOT_FOUND,"코디를 찾을 수 없습니다."),
    OUTFIT_CLOTHES_NOT_FOUND(HttpStatus.NOT_FOUND, "코디에 추가할 수 없는 옷이 포함되어 있습니다."),
    DUPLICATE_CLOTHES(HttpStatus.BAD_REQUEST, "같은 옷을 코디에 중복으로 추가할 수 없습니다."),
    OUTFIT_NAME_INVALID(HttpStatus.BAD_REQUEST, "코디 이름은 공백일 수 없습니다.");

    private final HttpStatus httpStatus;
    private final String message;
}
