package com.wearly.domain.recommendation.controller;

import com.wearly.domain.recommendation.dto.response.RecommendationResponse;
import com.wearly.domain.recommendation.service.RecommendationService;
import com.wearly.global.common.entity.Style;
import com.wearly.global.config.OpenApiConfig;
import com.wearly.global.security.WearlyUserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
@Validated
@Tag(name = "Recommendation", description = "실시간 코디 추천 API")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class RecommendationController {

    private final RecommendationService recommendationService;

    @Operation(
            summary = "실시간 코디 추천",
            description = "현재 날씨와 사용자 조건을 기반으로 코디 추천 결과를 조회한다."
    )
    @GetMapping
    public ResponseEntity<RecommendationResponse> getRecommendations(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @RequestParam
            @DecimalMin("-90.0")
            @DecimalMax("90.0")
            Double latitude,
            @RequestParam
            @DecimalMin("-180.0")
            @DecimalMax("180.0")
            Double longitude,
            @RequestParam(required = false)
            Style style,
            @RequestParam(defaultValue = "3")
            @Min(1)
            @Max(10)
            int limit
    ) {
        RecommendationResponse response =
                recommendationService.getRecommendations(
                        principal.getUserId(),
                        latitude,
                        longitude,
                        style,
                        limit
                );

        return ResponseEntity.ok(response);
    }
}
