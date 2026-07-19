package com.wearly.domain.clothes.service;

import com.wearly.infra.rembg.RembgApiClient;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class RembgService {

    private final RembgApiClient rembgApiClient;

    public byte[] removeBackground(
            byte[] imageBytes,
            String fileName,
            String contentType
    ) {
        return rembgApiClient.removeBackground(
                imageBytes,
                fileName,
                contentType
        );
    }
}
