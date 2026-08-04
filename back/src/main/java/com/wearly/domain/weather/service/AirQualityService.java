package com.wearly.domain.weather.service;

import com.wearly.domain.weather.entity.AirQuality;
import com.wearly.domain.weather.entity.DustGrade;
import com.wearly.infra.airkorea.AirKoreaApiClient;
import com.wearly.infra.airkorea.dto.AirKoreaMeasureResponse;
import com.wearly.infra.airkorea.dto.AirKoreaStationResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class AirQualityService {

    private static final Duration MEASURE_CACHE_DURATION = Duration.ofHours(1);

    private static final int MAX_STATION_ATTEMPTS = 3;

    private static final String NO_DATA = "-";

    private final AirKoreaApiClient airKoreaApiClient;

    private final Map<String, CachedMeasure> measureCache =
            new ConcurrentHashMap<>();

    private volatile List<Station> stationCache;

    public AirQuality getAirQuality(
            Double latitude,
            Double longitude
    ) {
        try {
            return findAirQuality(latitude, longitude);
        } catch (Exception e) {
            log.warn(
                    "Failed to load air quality. latitude: {}, longitude: {}",
                    latitude,
                    longitude,
                    e
            );

            return AirQuality.empty();
        }
    }

    private AirQuality findAirQuality(
            Double latitude,
            Double longitude
    ) {
        List<Station> nearestStations = findNearestStations(
                latitude,
                longitude
        );

        AirQuality fallback = null;

        for (Station station : nearestStations) {
            AirQuality airQuality = getMeasure(station.name());

            if (airQuality.pm10() != null && airQuality.pm25() != null) {
                return airQuality;
            }

            if (fallback == null
                    && (airQuality.pm10() != null
                    || airQuality.pm25() != null)) {
                fallback = airQuality;
            }
        }

        if (fallback != null) {
            return fallback;
        }

        return AirQuality.empty();
    }

    private AirQuality getMeasure(String stationName) {
        CachedMeasure cached = measureCache.get(stationName);

        if (cached != null && !isExpired(cached)) {
            return cached.airQuality();
        }

        AirKoreaMeasureResponse.MeasureItem item =
                airKoreaApiClient.getMeasure(stationName);

        AirQuality airQuality = convertAirQuality(item);

        measureCache.put(
                stationName,
                new CachedMeasure(airQuality, LocalDateTime.now())
        );

        return airQuality;
    }

    private boolean isExpired(CachedMeasure cached) {
        return cached.cachedAt()
                .plus(MEASURE_CACHE_DURATION)
                .isBefore(LocalDateTime.now());
    }

    private AirQuality convertAirQuality(
            AirKoreaMeasureResponse.MeasureItem item
    ) {
        if (item == null) {
            return AirQuality.empty();
        }

        Double pm10 = parseValue(item.getPm10Value());
        Double pm25 = parseValue(item.getPm25Value());

        DustGrade pm10Grade = parseGrade(
                item.getPm10Grade1h(),
                item.getPm10Grade()
        );
        DustGrade pm25Grade = parseGrade(
                item.getPm25Grade1h(),
                item.getPm25Grade()
        );

        return new AirQuality(
                pm10,
                pm25,
                chooseWorseGrade(pm10Grade, pm25Grade)
        );
    }

    private Double parseValue(String value) {
        if (value == null || value.isBlank() || NO_DATA.equals(value)) {
            return null;
        }

        try {
            return Double.parseDouble(value);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    // 공공누리 제3유형(변경금지)이라 등급은 직접 계산하지 않고
    // 에어코리아가 내려준 공식 등급을 그대로 쓴다.
    private DustGrade parseGrade(
            String hourlyGrade,
            String dailyGrade
    ) {
        DustGrade grade = convertGrade(hourlyGrade);

        if (grade != null) {
            return grade;
        }

        return convertGrade(dailyGrade);
    }

    private DustGrade convertGrade(String grade) {
        if (grade == null) {
            return null;
        }

        return switch (grade.trim()) {
            case "1" -> DustGrade.GOOD;
            case "2" -> DustGrade.MODERATE;
            case "3" -> DustGrade.BAD;
            case "4" -> DustGrade.VERY_BAD;
            default -> null;
        };
    }

    private DustGrade chooseWorseGrade(
            DustGrade pm10Grade,
            DustGrade pm25Grade
    ) {
        if (pm10Grade == null) {
            return pm25Grade;
        }

        if (pm25Grade == null) {
            return pm10Grade;
        }

        if (pm10Grade.ordinal() >= pm25Grade.ordinal()) {
            return pm10Grade;
        }

        return pm25Grade;
    }

    private List<Station> findNearestStations(
            Double latitude,
            Double longitude
    ) {
        List<Station> stations = getStations();

        return stations.stream()
                .sorted(Comparator.comparingDouble(
                        station -> distanceScore(
                                latitude,
                                longitude,
                                station
                        )
                ))
                .limit(MAX_STATION_ATTEMPTS)
                .toList();
    }

    // 순서만 비교하면 되므로 실제 거리 대신 제곱값을 쓴다.
    // 경도 1도의 실제 길이는 위도가 높을수록 짧아지므로 보정한다.
    private double distanceScore(
            double latitude,
            double longitude,
            Station station
    ) {
        double latitudeDiff = latitude - station.latitude();
        double longitudeDiff = (longitude - station.longitude())
                * Math.cos(Math.toRadians(latitude));

        return latitudeDiff * latitudeDiff
                + longitudeDiff * longitudeDiff;
    }

    private List<Station> getStations() {
        if (stationCache == null) {
            stationCache = loadStations();
        }

        return stationCache;
    }

    private List<Station> loadStations() {
        List<AirKoreaStationResponse.StationItem> items =
                airKoreaApiClient.getStations();

        List<Station> stations = new ArrayList<>();

        for (AirKoreaStationResponse.StationItem item : items) {
            Double latitude = parseValue(item.getDmX());
            Double longitude = parseValue(item.getDmY());

            if (item.getStationName() == null
                    || latitude == null
                    || longitude == null) {
                continue;
            }

            stations.add(new Station(
                    item.getStationName(),
                    latitude,
                    longitude
            ));
        }

        log.info("Air quality stations loaded. count: {}", stations.size());

        return stations;
    }

    private record Station(
            String name,
            double latitude,
            double longitude
    ) {
    }

    private record CachedMeasure(
            AirQuality airQuality,
            LocalDateTime cachedAt
    ) {
    }
}
