package com.wearly.domain.recommendation.dto.response;

import com.wearly.domain.weather.dto.response.WeatherResponse;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class RecommendationResponse {

    private WeatherResponse weather;
    private List<RecommendedOutfitResponse> recommendations;
}
