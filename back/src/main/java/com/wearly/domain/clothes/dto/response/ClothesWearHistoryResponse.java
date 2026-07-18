package com.wearly.domain.clothes.dto.response;

import com.wearly.domain.outfit.entity.OutfitHistoryItem;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class ClothesWearHistoryResponse {

    private Long historyId;
    private Long outfitId;
    private String outfitName;
    private LocalDate wornDate;

    public static ClothesWearHistoryResponse from(
            OutfitHistoryItem historyItem
    ) {
        return ClothesWearHistoryResponse.builder()
                .historyId(historyItem.getOutfitHistory().getId())
                .outfitId(historyItem.getOutfitHistory().getOutfits().getId())
                .outfitName(historyItem.getOutfitHistory().getOutfits().getName())
                .wornDate(historyItem.getOutfitHistory().getWornDate())
                .build();
    }
}
