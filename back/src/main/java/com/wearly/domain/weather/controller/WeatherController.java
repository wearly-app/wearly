package com.wearly.domain.weather.controller;

import com.wearly.domain.weather.dto.response.WeatherResponse;
import com.wearly.domain.weather.service.WeatherService;
import com.wearly.global.config.OpenApiConfig;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/weather")
@RequiredArgsConstructor
@Validated
@Tag(name = "Weather", description = "날씨 조회 API")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class WeatherController {

    private final WeatherService weatherService;

    @Operation(
            summary = "현재 날씨 조회",
            description = "위도와 경도를 기반으로 현재 날씨와 오늘 강수 예보, 미세먼지 정보를 조회한다."
    )
    @GetMapping
    public ResponseEntity<WeatherResponse> getCurrentWeather(
            @RequestParam
            @DecimalMin("-90.0")
            @DecimalMax("90.0")
            Double latitude,

            @RequestParam
            @DecimalMin("-180.0")
            @DecimalMax("180.0")
            Double longitude
    ) {
        WeatherResponse response =
                weatherService.getCurrentWeather(latitude, longitude);

        return ResponseEntity.ok(response);
    }
}
