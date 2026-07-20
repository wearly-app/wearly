package com.wearly.domain.recommendation.dto.response;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.entity.Clothes;
import com.wearly.global.common.entity.Style;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class RecommendationClothesResponse {

    private Long id;
    private String name;
    private Category category;
    private Style style;
    private String imageUrl;
    private String brand;
    private String material;
    private Integer thickness;
    private Double cloValue;
    private Integer wearCount;
    private LocalDate lastWornAt;

    public static RecommendationClothesResponse from(
            Clothes clothes,
            String imageUrl
    ) {
        return RecommendationClothesResponse.builder()
                .id(clothes.getId())
                .name(clothes.getName())
                .category(clothes.getCategory())
                .style(clothes.getStyle())
                .imageUrl(imageUrl)
                .brand(clothes.getBrand())
                .material(clothes.getMaterial())
                .thickness(clothes.getThickness())
                .cloValue(clothes.getCloValue())
                .wearCount(clothes.getWearCount())
                .lastWornAt(clothes.getLastWornAt())
                .build();
    }
}
