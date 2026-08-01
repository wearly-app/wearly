package com.wearly.domain.recommendation.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class RecommendedOutfitResponse {

    private Double totalClo;
    private Double score;
    private List<RecommendationClothesResponse> clothes;
}
