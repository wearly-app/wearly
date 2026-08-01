package com.wearly.domain.outfit.controller;

import com.wearly.domain.outfit.dto.response.DailyWearHistoryResponse;
import com.wearly.domain.outfit.dto.response.MonthlyWearHistoryResponse;
import com.wearly.domain.outfit.service.OutfitHistoryService;
import com.wearly.global.config.OpenApiConfig;
import com.wearly.global.security.WearlyUserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/histories")
@RequiredArgsConstructor
@Validated
@Tag(name = "History", description = "착용 기록 캘린더 API")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class OutfitHistoryController {

    private final OutfitHistoryService outfitHistoryService;

    @Operation(
            summary = "월별 착용 기록 조회",
            description = "해당 연월에 착용 기록이 있는 날짜와 코디 개수를 조회한다. 캘린더 표시에 사용한다."
    )
    @GetMapping("/monthly")
    public ResponseEntity<MonthlyWearHistoryResponse> getMonthlyWearHistory(
            @AuthenticationPrincipal WearlyUserPrincipal principal,

            @RequestParam
            @Min(2000) @Max(2100)
            int year,

            @RequestParam
            @Min(1) @Max(12)
            int month
    ) {
        MonthlyWearHistoryResponse response =
                outfitHistoryService.getMonthlyWearHistory(
                        principal.getUserId(),
                        year,
                        month
                );

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "일별 착용 기록 조회",
            description = "해당 날짜에 착용한 코디와 옷 목록을 조회한다."
    )
    @GetMapping("/daily")
    public ResponseEntity<List<DailyWearHistoryResponse>> getDailyWearHistory(
            @AuthenticationPrincipal WearlyUserPrincipal principal,

            @RequestParam
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {
        List<DailyWearHistoryResponse> response =
                outfitHistoryService.getDailyWearHistory(
                        principal.getUserId(),
                        date
                );

        return ResponseEntity.ok(response);
    }
}
