package com.wearly.domain.outfit.dto.response;

import com.wearly.domain.outfit.entity.OutfitHistory;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class OutfitWearResponse {

    private Long historyId;
    private Long outfitId;
    private LocalDate wornDate;
    private List<Long> clothesIds;
    private LocalDateTime createdAt;

    public static OutfitWearResponse from(
            OutfitHistory history,
            List<Long> clothesIds
    ) {
        return OutfitWearResponse.builder()
                .historyId(history.getId())
                .outfitId(history.getOutfits().getId())
                .wornDate(history.getWornDate())
                .clothesIds(clothesIds)
                .createdAt(history.getCreatedAt())
                .build();
    }
}