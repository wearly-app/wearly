package com.wearly.domain.clothes.controller;

import com.wearly.domain.clothes.dto.request.ClothesCreateRequest;
import com.wearly.domain.clothes.dto.request.ClothesUpdateRequest;
import com.wearly.domain.clothes.dto.response.ClothesResponse;
import com.wearly.domain.clothes.dto.response.ClothesAnalyzeResponse;
import com.wearly.domain.clothes.dto.response.ClothesWearHistoryResponse;
import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.service.ClothesService;
import com.wearly.domain.outfit.service.OutfitHistoryService;
import com.wearly.global.common.entity.Style;
import com.wearly.global.common.response.SliceResponse;
import com.wearly.global.config.OpenApiConfig;
import com.wearly.global.security.WearlyUserPrincipal;
import com.wearly.infra.s3.S3ImageStorage;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
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
@Validated
@Tag(name = "Clothes", description = "옷 등록 및 관리 API")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class ClothesController {

    private final ClothesService clothesService;
    private final OutfitHistoryService outfitHistoryService;
    private final S3ImageStorage s3ImageStorage;

    @Operation(summary = "옷 이미지 분석", description = "옷 이미지를 업로드하고 분석 결과를 반환한다.")
    @PostMapping("/analyze")
    public ResponseEntity<ClothesAnalyzeResponse> analyzeClothesImage(
            @RequestPart MultipartFile image
    ) {
        String imageKey = s3ImageStorage.upload(image);

        ClothesAnalyzeResponse response = ClothesAnalyzeResponse.builder()
                .imageUrl(imageKey)
                .build();
        // TODO: rembg 배경제거 + Vision API 연동 후 category/style/color/brand/material/thickness/cloValue 채우기

        return ResponseEntity.ok(response);
    }

    @Operation(summary = "옷 등록", description = "현재 사용자의 디지털 옷장에 새로운 옷을 등록한다.")
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

    @Operation(summary = "옷 목록 조회", description = "현재 사용자의 옷을 카테고리와 스타일 조건으로 조회한다.")
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

    @Operation(summary = "옷 상세 조회", description = "현재 사용자가 소유한 옷 한 개를 조회한다.")
    @GetMapping("/{id}")
    public ResponseEntity<ClothesResponse> getClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        ClothesResponse response = clothesService.getClothes(principal.getUserId(), id);

        return ResponseEntity.ok(response);
    }

    @Operation(summary = "옷 착용 이력 조회", description = "현재 사용자가 소유한 옷의 착용 이력을 최신순으로 조회한다.")
    @GetMapping("/{id}/history")
    public ResponseEntity<SliceResponse<ClothesWearHistoryResponse>> getClothesWearHistory(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(50) int size
    ) {
        SliceResponse<ClothesWearHistoryResponse> response =
                outfitHistoryService.getClothesWearHistory(
                        principal.getUserId(),
                        id,
                        page,
                        size
                );

        return ResponseEntity.ok(response);
    }

    @Operation(summary = "옷 수정", description = "현재 사용자가 소유한 옷의 정보를 선택적으로 수정한다.")
    @PatchMapping("/{id}")
    public ResponseEntity<ClothesResponse> updateClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody ClothesUpdateRequest request
    ) {
        ClothesResponse response = clothesService.updateClothes(principal.getUserId(), id, request);

        return ResponseEntity.ok(response);
    }

    @Operation(summary = "옷 삭제", description = "현재 사용자가 소유한 옷을 삭제한다.")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        clothesService.deleteClothes(principal.getUserId(), id);

        return ResponseEntity.noContent().build();
    }
}
