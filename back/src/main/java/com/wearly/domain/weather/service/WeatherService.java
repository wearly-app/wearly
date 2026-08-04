package com.wearly.domain.weather.service;

import com.wearly.domain.weather.dto.response.WeatherResponse;
import com.wearly.domain.weather.entity.AirQuality;
import com.wearly.domain.weather.entity.WeatherCondition;
import com.wearly.domain.weather.exception.WeatherErrorCode;
import com.wearly.domain.weather.exception.WeatherException;
import com.wearly.infra.weather.WeatherApiClient;
import com.wearly.infra.weather.dto.OpenWeatherForecastResponse;
import com.wearly.infra.weather.dto.OpenWeatherResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;

@Service
@RequiredArgsConstructor
public class WeatherService {

    private static final ZoneId KOREA_ZONE_ID = ZoneId.of("Asia/Seoul");

    private final WeatherApiClient weatherApiClient;
    private final AirQualityService airQualityService;

    public WeatherResponse getCurrentWeather(
            Double latitude,
            Double longitude
    ) {
        validateLocation(latitude, longitude);

        OpenWeatherResponse openWeatherResponse =
                weatherApiClient.getCurrentWeather(latitude, longitude);

        validateResponse(openWeatherResponse);

        OpenWeatherForecastResponse forecastResponse =
                weatherApiClient.getForecast(latitude, longitude);

        validateForecastResponse(forecastResponse);

        AirQuality airQuality = airQualityService.getAirQuality(
                latitude,
                longitude
        );

        OpenWeatherResponse.WeatherInfo weatherInfo =
                openWeatherResponse.getWeather().getFirst();

        return WeatherResponse.builder()
                .temperature(openWeatherResponse.getMain().getTemp())
                .feelsLikeTemperature(openWeatherResponse.getMain().getFeelsLike())
                .weather(convertWeatherCondition(weatherInfo.getMain()))
                .humidity(openWeatherResponse.getMain().getHumidity())
                .windSpeed(openWeatherResponse.getWind().getSpeed())
                .willRainToday(checkRainToday(forecastResponse))
                .maxRainProbability(calculateMaxRainProbability(forecastResponse))
                .pm10(airQuality.pm10())
                .pm25(airQuality.pm25())
                .dustGrade(airQuality.dustGrade())
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

    private void validateForecastResponse(OpenWeatherForecastResponse response) {
        if (response == null
                || response.getList() == null
                || response.getList().isEmpty()) {
            throw new WeatherException(
                    WeatherErrorCode.WEATHER_API_ERROR
            );
        }
    }

    private boolean checkRainToday(OpenWeatherForecastResponse response) {
        LocalDate today = LocalDate.now(KOREA_ZONE_ID);

        for (OpenWeatherForecastResponse.ForecastItem item : response.getList()) {
            if (!isToday(item, today)) {
                continue;
            }

            if (item.getWeather() == null || item.getWeather().isEmpty()) {
                continue;
            }

            if (isRainCondition(item.getWeather().getFirst().getMain())) {
                return true;
            }
        }

        return false;
    }

    private int calculateMaxRainProbability(OpenWeatherForecastResponse response) {
        LocalDate today = LocalDate.now(KOREA_ZONE_ID);
        int maxProbability = 0;

        for (OpenWeatherForecastResponse.ForecastItem item : response.getList()) {
            if (!isToday(item, today) || item.getPop() == null) {
                continue;
            }

            int probability = (int) Math.round(item.getPop() * 100);

            if (probability > maxProbability) {
                maxProbability = probability;
            }
        }

        return maxProbability;
    }

    private boolean isToday(
            OpenWeatherForecastResponse.ForecastItem item,
            LocalDate today
    ) {
        if (item.getDt() == null) {
            return false;
        }

        return convertObservedAt(item.getDt())
                .toLocalDate()
                .equals(today);
    }

    private boolean isRainCondition(String weather) {
        return "Rain".equals(weather)
                || "Drizzle".equals(weather)
                || "Thunderstorm".equals(weather);
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
