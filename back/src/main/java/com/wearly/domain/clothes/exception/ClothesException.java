package com.wearly.domain.clothes.exception;

import com.wearly.global.exception.ApplicationException;

public class ClothesException extends ApplicationException {

    public ClothesException(ClothesErrorCode errorCode) {
        super(errorCode);
    }
}
