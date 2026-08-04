package com.wearly.domain.weather.exception;

import com.wearly.global.exception.ErrorCode;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum WeatherErrorCode implements ErrorCode {

    INVALID_LOCATION(HttpStatus.BAD_REQUEST, "유효하지 않은 위치 정보입니다."),
    WEATHER_API_ERROR(HttpStatus.BAD_GATEWAY, "날씨 서버와 통신 중 오류가 발생했습니다."),
    INVALID_WEATHER_API_KEY(HttpStatus.BAD_GATEWAY, "날씨 API 인증에 실패했습니다."),
    AIR_QUALITY_API_ERROR(HttpStatus.BAD_GATEWAY, "미세먼지 정보 조회에 실패했습니다.");

    private final HttpStatus httpStatus;
    private final String message;
}
