package com.wearly.infra.weather.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class OpenWeatherAirPollutionResponse {

    private List<AirPollutionItem> list;

    @Getter
    @NoArgsConstructor
    public static class AirPollutionItem {

        private Components components;
    }

    @Getter
    @NoArgsConstructor
    public static class Components {

        private Double pm10;

        @JsonProperty("pm2_5")
        private Double pm25;
    }
}
