package com.wearly.domain.recommendation.service;

import com.wearly.domain.recommendation.dto.response.RecommendationResponse;
import com.wearly.domain.weather.dto.response.WeatherResponse;
import com.wearly.domain.weather.service.WeatherService;
import com.wearly.global.common.entity.Style;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RecommendationService {

    private final WeatherService weatherService;

    public RecommendationResponse getRecommendations(
            Long userId,
            Double latitude,
            Double longitude,
            Style requestedStyle,
            int limit
    ) {
        WeatherResponse weather = weatherService.getCurrentWeather(
                latitude,
                longitude
        );

        return RecommendationResponse.builder()
                .weather(weather)
                .recommendations(List.of())
                .build();
    }
}
