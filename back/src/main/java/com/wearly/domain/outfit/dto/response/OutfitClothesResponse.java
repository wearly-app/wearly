package com.wearly.domain.outfit.dto.response;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.entity.Clothes;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class OutfitClothesResponse {

    private Long id;
    private Category category;
    private String imageUrl;
    private String brand;

    public static OutfitClothesResponse from(Clothes clothes, String imageUrl) {
        return OutfitClothesResponse.builder()
                .id(clothes.getId())
                .category(clothes.getCategory())
                .imageUrl(imageUrl)
                .brand(clothes.getBrand())
                .build();
    }
}
