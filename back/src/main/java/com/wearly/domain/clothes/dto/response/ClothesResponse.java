package com.wearly.domain.clothes.dto.response;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.entity.Clothes;
import com.wearly.global.common.entity.Style;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class ClothesResponse {

    private Long id;
    private Category category;
    private Style style;
    private String imageUrl;

    private Integer colorH;
    private Integer colorS;
    private Integer colorV;

    private String brand;
    private String material;
    private Integer thickness;
    private Double cloValue;

    private Integer wearCount;
    private LocalDate lastWornAt;

    public static ClothesResponse from(Clothes clothes) {
        return ClothesResponse.builder()
                .id(clothes.getId())
                .category(clothes.getCategory())
                .style(clothes.getStyle())
                .imageUrl(clothes.getImageUrl())
                .colorH(clothes.getColorH())
                .colorS(clothes.getColorS())
                .colorV(clothes.getColorV())
                .brand(clothes.getBrand())
                .material(clothes.getMaterial())
                .thickness(clothes.getThickness())
                .cloValue(clothes.getCloValue())
                .wearCount(clothes.getWearCount())
                .lastWornAt(clothes.getLastWornAt())
                .build();
    }
}
