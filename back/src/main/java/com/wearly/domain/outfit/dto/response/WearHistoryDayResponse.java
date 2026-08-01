package com.wearly.domain.outfit.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class WearHistoryDayResponse {

    private LocalDate wornDate;
    private int outfitCount;

    public static WearHistoryDayResponse of(LocalDate wornDate, int outfitCount) {
        return WearHistoryDayResponse.builder()
                .wornDate(wornDate)
                .outfitCount(outfitCount)
                .build();
    }
}
