package com.wearly.infra.weather.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class OpenWeatherResponse {

    private List<WeatherInfo> weather;
    private MainInfo main;
    private WindInfo wind;
    private Long dt;

    @Getter
    @NoArgsConstructor
    public static class WeatherInfo {

        private String main;
        private String description;
    }

    @Getter
    @NoArgsConstructor
    public static class MainInfo {

        private Double temp;

        @JsonProperty("feels_like")
        private Double feelsLike;

        private Integer humidity;
    }

    @Getter
    @NoArgsConstructor
    public static class WindInfo {

        private Double speed;
    }
}
