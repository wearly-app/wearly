package com.wearly.domain.weather.service;

import com.wearly.domain.weather.dto.response.WeatherResponse;
import com.wearly.domain.weather.entity.DustGrade;
import com.wearly.domain.weather.entity.WeatherCondition;
import com.wearly.domain.weather.exception.WeatherErrorCode;
import com.wearly.domain.weather.exception.WeatherException;
import com.wearly.infra.weather.WeatherApiClient;
import com.wearly.infra.weather.dto.OpenWeatherAirPollutionResponse;
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

    // 환경부 미세먼지 등급 기준 (㎍/㎥)
    private static final double PM10_GOOD_MAX = 30;
    private static final double PM10_MODERATE_MAX = 80;
    private static final double PM10_BAD_MAX = 150;

    private static final double PM25_GOOD_MAX = 15;
    private static final double PM25_MODERATE_MAX = 35;
    private static final double PM25_BAD_MAX = 75;

    private final WeatherApiClient weatherApiClient;

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

        // TODO: 임시 소스. OpenWeather 미세먼지는 지상 측정값이 아니라 대기 모델
        //  계산값이라 한국 지역에서 실측 대비 5~9배까지 과대평가된다.
        //  (수원 확인: PM10 160 / PM2.5 142 → 실제 30 / 20)
        //  에어코리아 API로 교체할 것. 등급 기준과 DustGrade는 그대로 재사용 가능.
        OpenWeatherAirPollutionResponse airPollutionResponse =
                weatherApiClient.getAirPollution(latitude, longitude);

        validateAirPollutionResponse(airPollutionResponse);

        OpenWeatherResponse.WeatherInfo weatherInfo =
                openWeatherResponse.getWeather().getFirst();

        OpenWeatherAirPollutionResponse.Components components =
                airPollutionResponse.getList().getFirst().getComponents();

        Double pm10 = components.getPm10();
        Double pm25 = components.getPm25();

        return WeatherResponse.builder()
                .temperature(openWeatherResponse.getMain().getTemp())
                .feelsLikeTemperature(openWeatherResponse.getMain().getFeelsLike())
                .weather(convertWeatherCondition(weatherInfo.getMain()))
                .humidity(openWeatherResponse.getMain().getHumidity())
                .windSpeed(openWeatherResponse.getWind().getSpeed())
                .willRainToday(checkRainToday(forecastResponse))
                .maxRainProbability(calculateMaxRainProbability(forecastResponse))
                .pm10(pm10)
                .pm25(pm25)
                .dustGrade(calculateDustGrade(pm10, pm25))
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

    private void validateAirPollutionResponse(OpenWeatherAirPollutionResponse response) {
        if (response == null
                || response.getList() == null
                || response.getList().isEmpty()
                || response.getList().getFirst().getComponents() == null) {
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

    private DustGrade calculateDustGrade(
            Double pm10,
            Double pm25
    ) {
        if (pm10 == null || pm25 == null) {
            return null;
        }

        DustGrade pm10Grade = convertPm10Grade(pm10);
        DustGrade pm25Grade = convertPm25Grade(pm25);

        // 둘 중 더 나쁜 등급을 최종 등급으로 사용한다.
        if (pm10Grade.ordinal() >= pm25Grade.ordinal()) {
            return pm10Grade;
        }

        return pm25Grade;
    }

    private DustGrade convertPm10Grade(double pm10) {
        if (pm10 <= PM10_GOOD_MAX) {
            return DustGrade.GOOD;
        }

        if (pm10 <= PM10_MODERATE_MAX) {
            return DustGrade.MODERATE;
        }

        if (pm10 <= PM10_BAD_MAX) {
            return DustGrade.BAD;
        }

        return DustGrade.VERY_BAD;
    }

    private DustGrade convertPm25Grade(double pm25) {
        if (pm25 <= PM25_GOOD_MAX) {
            return DustGrade.GOOD;
        }

        if (pm25 <= PM25_MODERATE_MAX) {
            return DustGrade.MODERATE;
        }

        if (pm25 <= PM25_BAD_MAX) {
            return DustGrade.BAD;
        }

        return DustGrade.VERY_BAD;
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
