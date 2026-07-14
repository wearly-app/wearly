package com.wearly.domain.outfit.dto.response;

import com.wearly.domain.outfit.entity.Outfits;
import com.wearly.global.common.entity.Style;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class OutfitResponse {

    private Long id;
    private String name;
    private Style style;
    private String thumbnailUrl;
    private boolean favorite;
    private List<OutfitClothesResponse> clothes;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static OutfitResponse from(
            Outfits outfit,
            List<OutfitClothesResponse> clothes
    ) {
        return OutfitResponse.builder()
                .id(outfit.getId())
                .name(outfit.getName())
                .style(outfit.getStyle())
                .thumbnailUrl(outfit.getThumbnailUrl())
                .favorite(outfit.isFavorite())
                .clothes(clothes)
                .createdAt(outfit.getCreatedAt())
                .updatedAt(outfit.getUpdatedAt())
                .build();
    }
}
