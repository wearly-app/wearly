package com.wearly.infra.weather.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class OpenWeatherForecastResponse {

    private List<ForecastItem> list;

    @Getter
    @NoArgsConstructor
    public static class ForecastItem {

        private Long dt;
        private List<WeatherInfo> weather;

        // 강수 확률 (0.0 ~ 1.0)
        private Double pop;
    }

    @Getter
    @NoArgsConstructor
    public static class WeatherInfo {

        private String main;
    }
}
