package com.wearly.infra.s3;

import com.wearly.global.exception.ApplicationException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.io.IOException;
import java.time.Duration;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class S3ImageStorage {

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;

    @Value("${cloud.aws.s3.bucket}")
    private String bucket;

    public String upload(MultipartFile file) {
        String key = "clothes/"
                + UUID.randomUUID()
                + "-"
                + file.getOriginalFilename();

        try {
            PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(file.getContentType())
                    .build();

            s3Client.putObject(
                    request,
                    RequestBody.fromInputStream(
                            file.getInputStream(),
                            file.getSize()
                    )
            );

            return key;
        } catch (IOException e) {
            throw new ApplicationException(
                    S3ErrorCode.IMAGE_UPLOAD_FAILED
            );
        }
    }

    public String upload(
            byte[] imageBytes,
            String extension,
            String contentType
    ) {
        String key = "clothes/" + UUID.randomUUID() + "." + extension;

        try {
            PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(contentType)
                    .contentLength((long) imageBytes.length)
                    .build();

            s3Client.putObject(
                    request,
                    RequestBody.fromBytes(imageBytes)
            );

            return key;
        } catch (Exception e) {
            throw new ApplicationException(
                    S3ErrorCode.IMAGE_UPLOAD_FAILED
            );
        }
    }

    public String getUrl(String key) {
        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))   // 10분간만 유효
                .getObjectRequest(b -> b.bucket(bucket).key(key))
                .build();

        return s3Presigner.presignGetObject(presignRequest).url().toString();
    }
}
