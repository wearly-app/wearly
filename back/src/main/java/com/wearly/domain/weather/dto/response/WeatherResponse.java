package com.wearly.domain.weather.dto.response;

import com.wearly.domain.weather.entity.WeatherCondition;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class WeatherResponse {

    private Double temperature;
    private Double feelsLikeTemperature;
    private WeatherCondition weather;
    private Integer humidity;
    private Double windSpeed;
    private LocalDateTime observedAt;
}
