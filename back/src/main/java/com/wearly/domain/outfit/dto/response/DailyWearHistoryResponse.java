package com.wearly.domain.outfit.dto.response;

import com.wearly.domain.outfit.entity.OutfitHistory;
import com.wearly.global.common.entity.Style;
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
    private Style style;
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
                .style(history.getOutfits().getStyle())
                .wornDate(history.getWornDate())
                .clothes(clothes)
                .build();
    }
}
