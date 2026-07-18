package com.wearly.domain.weather.service;

import com.wearly.domain.weather.dto.response.WeatherResponse;
import com.wearly.domain.weather.entity.WeatherCondition;
import com.wearly.domain.weather.exception.WeatherErrorCode;
import com.wearly.domain.weather.exception.WeatherException;
import com.wearly.infra.weather.WeatherApiClient;
import com.wearly.infra.weather.dto.OpenWeatherResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;

@Service
@RequiredArgsConstructor
public class WeatherService {

    private static final ZoneId KOREA_ZONE_ID = ZoneId.of("Asia/Seoul");

    private final WeatherApiClient weatherApiClient;

    public WeatherResponse getCurrentWeather(
            Double latitude,
            Double longitude
    ) {
        validateLocation(latitude, longitude);

        OpenWeatherResponse openWeatherResponse =
                weatherApiClient.getCurrentWeather(latitude, longitude);

        validateResponse(openWeatherResponse);

        OpenWeatherResponse.WeatherInfo weatherInfo =
                openWeatherResponse.getWeather().getFirst();

        return WeatherResponse.builder()
                .temperature(openWeatherResponse.getMain().getTemp())
                .feelsLikeTemperature(openWeatherResponse.getMain().getFeelsLike())
                .weather(convertWeatherCondition(weatherInfo.getMain()))
                .humidity(openWeatherResponse.getMain().getHumidity())
                .windSpeed(openWeatherResponse.getWind().getSpeed())
                .observedAt(convertObservedAt(openWeatherResponse.getDt()))
                .build();
    }

    private void validateLocation(
            Double latitude,
            Double longitude
    ) {
        if (latitude == null
                || latitude < -90
                || latitude > 90
                || longitude == null
                || longitude < -180
                || longitude > 180) {
            throw new WeatherException(
                    WeatherErrorCode.INVALID_LOCATION
            );
        }
    }

    private void validateResponse(OpenWeatherResponse response) {
        if (response == null
                || response.getWeather() == null
                || response.getWeather().isEmpty()
                || response.getMain() == null
                || response.getWind() == null
                || response.getDt() == null) {
            throw new WeatherException(
                    WeatherErrorCode.WEATHER_API_ERROR
            );
        }
    }

    private WeatherCondition convertWeatherCondition(String weather) {
        return switch (weather) {
            case "Clear" -> WeatherCondition.CLEAR;
            case "Rain", "Drizzle", "Thunderstorm" -> WeatherCondition.RAIN;
            case "Snow" -> WeatherCondition.SNOW;
            default -> WeatherCondition.CLOUDY;
        };
    }

    private LocalDateTime convertObservedAt(Long timestamp) {
        return LocalDateTime.ofInstant(
                Instant.ofEpochSecond(timestamp),
                KOREA_ZONE_ID
        );
    }
}
