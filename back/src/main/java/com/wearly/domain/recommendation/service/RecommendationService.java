package com.wearly.domain.recommendation.service;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.entity.Clothes;
import com.wearly.domain.clothes.repository.ClothesRepository;
import com.wearly.domain.recommendation.dto.response.RecommendationClothesResponse;
import com.wearly.domain.recommendation.dto.response.RecommendationResponse;
import com.wearly.domain.recommendation.dto.response.RecommendedOutfitResponse;
import com.wearly.domain.weather.dto.response.WeatherResponse;
import com.wearly.domain.weather.service.WeatherService;
import com.wearly.global.common.entity.Style;
import com.wearly.infra.s3.S3ImageStorage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RecommendationService {

    private final WeatherService weatherService;
    private final ClothesRepository clothesRepository;
    private final S3ImageStorage s3ImageStorage;

    public RecommendationResponse getRecommendations(
            Long userId,
            Double latitude,
            Double longitude,
            Style requestedStyle,
            int limit
    ) {
        WeatherResponse weather = weatherService.getCurrentWeather(
                latitude,
                longitude
        );
        List<Clothes> wardrobe = clothesRepository
                .findByUser_IdAndDeletedAtIsNull(userId);
        double targetClo = targetCloFor(weather.getFeelsLikeTemperature() != null
                ? weather.getFeelsLikeTemperature()
                : weather.getTemperature());

        List<Clothes> tops = clothesByCategory(wardrobe, Category.TOP);
        List<Clothes> bottoms = clothesByCategory(wardrobe, Category.BOTTOM);
        List<Clothes> outers = clothesByCategory(wardrobe, Category.OUTER);

        List<OutfitCandidate> candidates = new ArrayList<>();
        for (Clothes top : tops) {
            for (Clothes bottom : bottoms) {
                candidates.add(createCandidate(
                        List.of(top, bottom),
                        targetClo,
                        requestedStyle
                ));

                if (targetClo >= 1.0) {
                    for (Clothes outer : outers) {
                        candidates.add(createCandidate(
                                List.of(top, bottom, outer),
                                targetClo,
                                requestedStyle
                        ));
                    }
                }
            }
        }

        List<RecommendedOutfitResponse> recommendations = candidates.stream()
                .sorted(Comparator.comparingDouble(OutfitCandidate::score).reversed())
                .limit(limit)
                .map(this::toResponse)
                .toList();

        return RecommendationResponse.builder()
                .weather(weather)
                .recommendations(recommendations)
                .build();
    }

    private List<Clothes> clothesByCategory(
            List<Clothes> wardrobe,
            Category category
    ) {
        return wardrobe.stream()
                .filter(clothes -> clothes.getCategory() == category)
                .toList();
    }

    private OutfitCandidate createCandidate(
            List<Clothes> clothes,
            double targetClo,
            Style requestedStyle
    ) {
        double totalClo = clothes.stream()
                .mapToDouble(this::cloValueOf)
                .sum();

        // 기온 적합도 50점: 목표 CLO에 가까울수록 높은 점수를 준다.
        double cloDifferenceRatio = Math.abs(totalClo - targetClo)
                / Math.max(targetClo, 0.3);
        double weatherScore = Math.max(0.0, 1.0 - cloDifferenceRatio) * 50.0;

        // 방치 의류 구출 35점: 오래 안 입었고 착용 횟수가 적은 옷을 우선한다.
        double neglectScore = clothes.stream()
                .mapToDouble(this::neglectRatio)
                .average()
                .orElse(0.0) * 35.0;

        // 요청 스타일 적합도 15점: 모든 구성품이 요청 스타일이면 만점을 준다.
        double styleScore = clothes.stream()
                .mapToDouble(clothesItem -> styleRatio(clothesItem, requestedStyle))
                .average()
                .orElse(0.0) * 15.0;

        double score = roundToOneDecimal(
                weatherScore + neglectScore + styleScore
        );

        return new OutfitCandidate(
                clothes,
                roundToTwoDecimals(totalClo),
                score
        );
    }

    private double cloValueOf(Clothes clothes) {
        if (clothes.getCloValue() != null && clothes.getCloValue() > 0) {
            return clothes.getCloValue();
        }

        int thickness = clothes.getThickness() == null
                ? 2
                : clothes.getThickness();
        double estimatedClo = switch (thickness) {
            case 1 -> 0.20;
            case 3 -> 0.55;
            default -> 0.35;
        };

        if (clothes.getCategory() == Category.OUTER) {
            estimatedClo += 0.20;
        }
        return estimatedClo;
    }

    private double neglectRatio(Clothes clothes) {
        LocalDate lastWornAt = clothes.getLastWornAt();
        double daysRatio;
        if (lastWornAt == null) {
            daysRatio = 1.0;
        } else {
            long neglectedDays = Math.max(
                    0,
                    ChronoUnit.DAYS.between(lastWornAt, LocalDate.now())
            );
            daysRatio = Math.min(neglectedDays / 90.0, 1.0);
        }

        int wearCount = clothes.getWearCount() == null
                ? 0
                : clothes.getWearCount();
        double lowWearRatio = 1.0 / (1.0 + wearCount);

        return (daysRatio * 0.8) + (lowWearRatio * 0.2);
    }

    private double styleRatio(Clothes clothes, Style requestedStyle) {
        if (requestedStyle == null) {
            return 1.0;
        }
        if (clothes.getStyle() == null) {
            return 0.5;
        }
        return clothes.getStyle() == requestedStyle ? 1.0 : 0.0;
    }

    /**
     * 시연용 ASHRAE 기반 기온 구간별 목표 착의량(CLO) 매핑.
     * 체감온도가 있으면 체감온도를 우선 사용한다.
     */
    private double targetCloFor(Double temperature) {
        double value = temperature == null ? 22.0 : temperature;
        if (value >= 28.0) return 0.36;
        if (value >= 26.0) return 0.50;
        if (value >= 23.0) return 0.70;
        if (value >= 20.0) return 1.00;
        if (value >= 15.0) return 1.30;
        if (value >= 10.0) return 1.60;
        return 2.00;
    }

    private RecommendedOutfitResponse toResponse(OutfitCandidate candidate) {
        List<RecommendationClothesResponse> clothes = candidate.clothes().stream()
                .map(item -> RecommendationClothesResponse.from(
                        item,
                        imageUrlOf(item)
                ))
                .toList();

        return RecommendedOutfitResponse.builder()
                .totalClo(candidate.totalClo())
                .score(candidate.score())
                .clothes(clothes)
                .build();
    }

    private String imageUrlOf(Clothes clothes) {
        String imageKey = clothes.getImageKey();
        if (imageKey == null || imageKey.isBlank()) {
            return null;
        }
        if (imageKey.startsWith("http://") || imageKey.startsWith("https://")) {
            return imageKey;
        }
        return s3ImageStorage.getUrl(imageKey);
    }

    private double roundToOneDecimal(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private double roundToTwoDecimals(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private record OutfitCandidate(
            List<Clothes> clothes,
            double totalClo,
            double score
    ) {
    }
}
