package com.wearly.domain.weather.exception;

import com.wearly.global.exception.ApplicationException;
import com.wearly.global.exception.ErrorCode;

public class WeatherException extends ApplicationException {

    public WeatherException(ErrorCode errorCode) {
        super(errorCode);
    }
}
