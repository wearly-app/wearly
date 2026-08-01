package com.wearly.domain.outfit.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MonthlyWearHistoryResponse {

    private int year;
    private int month;
    private List<WearHistoryDayResponse> days;

    public static MonthlyWearHistoryResponse of(
            int year,
            int month,
            List<WearHistoryDayResponse> days
    ) {
        return MonthlyWearHistoryResponse.builder()
                .year(year)
                .month(month)
                .days(days)
                .build();
    }
}
