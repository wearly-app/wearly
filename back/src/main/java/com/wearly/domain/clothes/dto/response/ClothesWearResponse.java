package com.wearly.domain.clothes.dto.response;

import com.wearly.domain.clothes.entity.Clothes;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class ClothesWearResponse {

    private Long clothesId;
    private Integer wearCount;
    private LocalDate lastWornAt;

    public static ClothesWearResponse from(Clothes clothes) {
        return ClothesWearResponse.builder()
                .clothesId(clothes.getId())
                .wearCount(clothes.getWearCount())
                .lastWornAt(clothes.getLastWornAt())
                .build();
    }
}
