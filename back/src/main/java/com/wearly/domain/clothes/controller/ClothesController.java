package com.wearly.domain.clothes.controller;

import com.wearly.domain.clothes.dto.request.ClothesCreateRequest;
import com.wearly.domain.clothes.dto.request.ClothesUpdateRequest;
import com.wearly.domain.clothes.dto.response.ClothesResponse;
import com.wearly.domain.clothes.dto.response.ClothesAnalyzeResponse;
import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.service.ClothesService;
import com.wearly.domain.clothes.service.RembgService;
import com.wearly.domain.clothes.service.GeminiApiClient;
import com.wearly.global.common.entity.Style;
import com.wearly.global.security.WearlyUserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/clothes")
@RequiredArgsConstructor
public class ClothesController {

    private final ClothesService clothesService;
    private final RembgService rembgService;
    private final GeminiApiClient geminiApiClient;

    @PostMapping("/analyze")
    public ResponseEntity<ClothesAnalyzeResponse> analyzeClothesImage(
            @RequestPart MultipartFile image
    ) {
        try {
            byte[] originalBytes = image.getBytes();

            // 1. Remove background (누끼 따기)
            byte[] processedBytes = rembgService.removeBackground(originalBytes);

            // Convert to Base64 to send to Gemini & to return as Data URI
            String base64Image = java.util.Base64.getEncoder().encodeToString(processedBytes);
            String imageUrl = "data:image/png;base64," + base64Image;

            // 2. Call Gemini API to analyze clothes info
            ClothesAnalyzeResponse response = geminiApiClient.analyzeClothingImage(processedBytes, base64Image);

            // 3. Update response with the transparent imageUrl
            ClothesAnalyzeResponse finalResponse = ClothesAnalyzeResponse.builder()
                    .imageUrl(imageUrl)
                    .category(response.getCategory())
                    .style(response.getStyle())
                    .colorH(response.getColorH())
                    .colorS(response.getColorS())
                    .colorV(response.getColorV())
                    .brand(response.getBrand())
                    .material(response.getMaterial())
                    .thickness(response.getThickness())
                    .cloValue(response.getCloValue())
                    .build();

            return ResponseEntity.ok(finalResponse);
        } catch (Exception e) {
            throw new RuntimeException("Failed to analyze clothes image", e);
        }
    }

    @PostMapping
    public ResponseEntity<ClothesResponse> createClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @Valid @RequestBody ClothesCreateRequest request
    ) {
        ClothesResponse response = clothesService.createClothes(principal.getUserId(), request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @GetMapping
    public ResponseEntity<List<ClothesResponse>> getClothesList(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @RequestParam(required = false) Category category,
            @RequestParam(required = false) Style style
    ) {
        List<ClothesResponse> response = clothesService.getClothesList(
                principal.getUserId(),
                category,
                style);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClothesResponse> getClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        ClothesResponse response = clothesService.getClothes(principal.getUserId(), id);

        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ClothesResponse> updateClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody ClothesUpdateRequest request
    ) {
        ClothesResponse response = clothesService.updateClothes(principal.getUserId(), id, request);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        clothesService.deleteClothes(principal.getUserId(), id);

        return ResponseEntity.noContent().build();
    }
}
