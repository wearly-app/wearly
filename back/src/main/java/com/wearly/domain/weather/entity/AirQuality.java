package com.wearly.domain.weather.entity;

public record AirQuality(
        Double pm10,
        Double pm25,
        DustGrade dustGrade
) {

    public static AirQuality empty() {
        return new AirQuality(null, null, null);
    }
}
