package com.wearly.infra.s3;

import com.wearly.infra.s3.dto.ImageUploadResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/images")
@RequiredArgsConstructor
public class ImageController {

    private final S3ImageStorage s3ImageStorage;

    @PostMapping
    public ResponseEntity<ImageUploadResponse> uploadImage(
            @RequestPart("image") MultipartFile image
    ) {
        String imageKey = s3ImageStorage.upload(image);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(new ImageUploadResponse(imageKey));
    }
}
