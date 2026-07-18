package com.wearly.domain.outfit.exception;

import com.wearly.global.exception.ApplicationException;
import com.wearly.global.exception.ErrorCode;

public class OutfitException extends ApplicationException {

    public OutfitException(ErrorCode errorCode) {
        super(errorCode);
    }
}
