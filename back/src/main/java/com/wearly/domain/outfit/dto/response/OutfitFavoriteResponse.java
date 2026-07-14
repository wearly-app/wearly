package com.wearly.domain.outfit.dto.response;

import com.wearly.domain.outfit.entity.Outfits;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class OutfitFavoriteResponse {

    private Long outfitId;
    private boolean favorite;

    public static OutfitFavoriteResponse from(Outfits outfit) {
        return OutfitFavoriteResponse.builder()
                .outfitId(outfit.getId())
                .favorite(outfit.isFavorite())
                .build();
    }
}
