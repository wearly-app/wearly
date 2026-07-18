package com.wearly.domain.clothes.dto.response;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.global.common.entity.Style;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ClothesAnalyzeResponse {

    private String imageUrl;

    private Category category;

    private Style style;

    private Integer colorH;
    private Integer colorS;
    private Integer colorV;

    private String brand;
    private String name;
    private String material;

    private Integer thickness;

    private Double cloValue;
}