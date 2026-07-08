package com.wearly.domain.user.exception;

import com.wearly.global.exception.ApplicationException;
import com.wearly.global.exception.ErrorCode;

public class UserException extends ApplicationException {

    public UserException(ErrorCode errorCode) {
        super(errorCode);
    }
}
