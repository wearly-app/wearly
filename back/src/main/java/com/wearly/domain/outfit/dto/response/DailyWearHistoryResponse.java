package com.wearly.domain.outfit.dto.response;

import com.wearly.domain.outfit.entity.OutfitHistory;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class DailyWearHistoryResponse {

    private Long historyId;
    private Long outfitId;
    private String outfitName;
    private LocalDate wornDate;
    private List<OutfitClothesResponse> clothes;

    public static DailyWearHistoryResponse from(
            OutfitHistory history,
            List<OutfitClothesResponse> clothes
    ) {
        return DailyWearHistoryResponse.builder()
                .historyId(history.getId())
                .outfitId(history.getOutfits().getId())
                .outfitName(history.getOutfits().getName())
                .wornDate(history.getWornDate())
                .clothes(clothes)
                .build();
    }
}
