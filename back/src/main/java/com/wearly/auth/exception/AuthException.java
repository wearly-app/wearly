package com.wearly.auth.exception;

import com.wearly.global.exception.ApplicationException;
import com.wearly.global.exception.ErrorCode;

public class AuthException extends ApplicationException {

    public AuthException(ErrorCode errorCode) {
        super(errorCode);
    }
}
