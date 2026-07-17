package com.wearly.domain.outfit.controller;

import com.wearly.domain.outfit.dto.request.OutfitCreateRequest;
import com.wearly.domain.outfit.dto.request.OutfitUpdateRequest;
import com.wearly.domain.outfit.dto.response.OutfitFavoriteResponse;
import com.wearly.domain.outfit.dto.response.OutfitResponse;
import com.wearly.domain.outfit.dto.response.OutfitWearResponse;
import com.wearly.domain.outfit.service.OutfitHistoryService;
import com.wearly.domain.outfit.service.OutfitService;
import com.wearly.global.common.response.SliceResponse;
import com.wearly.global.config.OpenApiConfig;
import com.wearly.global.security.WearlyUserPrincipal;
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
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/outfits")
@RequiredArgsConstructor
@Validated
@Tag(name = "Outfit", description = "코디 저장 및 관리 API")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class OutfitController {

    private final OutfitService outfitService;
    private final OutfitHistoryService outfitHistoryService;

    @Operation(summary = "코디 생성", description = "현재 사용자의 옷을 조합해 새로운 코디를 저장한다.")
    @PostMapping
    public ResponseEntity<OutfitResponse> createOutfit(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @Valid @RequestBody OutfitCreateRequest request
    ) {
        OutfitResponse response = outfitService.createOutfit(
                principal.getUserId(),
                request
        );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @Operation(summary = "코디 상세 조회", description = "현재 사용자가 소유한 코디 한 개를 조회한다.")
    @GetMapping("/{id}")
    public ResponseEntity<OutfitResponse> getOutfit(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        OutfitResponse response = outfitService.getOutfit(
                principal.getUserId(),
                id
        );

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "코디 목록 조회",
            description = "코디를 최신순으로 조회한다. 즐겨찾기 필터와 Slice 페이지네이션을 지원한다."
    )
    @GetMapping
    public ResponseEntity<SliceResponse<OutfitResponse>> getOutfits(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @RequestParam(required = false) Boolean favorite,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(50) int size
    ) {
        SliceResponse<OutfitResponse> response = outfitService.getOutfits(
                principal.getUserId(),
                favorite,
                page,
                size
        );

        return ResponseEntity.ok(response);
    }

    @Operation(summary = "코디 삭제", description = "현재 사용자가 소유한 코디를 삭제한다.")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteOutfit(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        outfitService.deleteOutfit(
                principal.getUserId(),
                id
        );

        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "코디 수정", description = "코디 이름, 스타일, 옷 구성을 선택적으로 수정한다.")
    @PatchMapping("/{id}")
    public ResponseEntity<OutfitResponse> updateOutfit(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody OutfitUpdateRequest request
    ) {
        OutfitResponse response = outfitService.updateOutfit(
                principal.getUserId(),
                id,
                request
        );

        return ResponseEntity.ok(response);
    }

    @Operation(summary = "코디 즐겨찾기 토글", description = "코디의 즐겨찾기 상태를 반대로 변경한다.")
    @PatchMapping("/{id}/favorite")
    public ResponseEntity<OutfitFavoriteResponse> toggleFavorite(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        OutfitFavoriteResponse response =
                outfitService.toggleFavorite(
                        principal.getUserId(),
                        id
                );

        return ResponseEntity.ok(response);
    }

    @Operation(summary = "코디 착용 기록", description = "현재 사용자가 소유한 코디를 오늘 입은 것으로 기록한다.")
    @PostMapping("/{id}/wear")
    public ResponseEntity<OutfitWearResponse> wearOutfit(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        OutfitWearResponse response = outfitHistoryService.wearOutfit(
                principal.getUserId(),
                id
        );

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
