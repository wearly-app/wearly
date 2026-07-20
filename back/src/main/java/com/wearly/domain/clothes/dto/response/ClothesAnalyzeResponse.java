package com.wearly.domain.clothes.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.wearly.domain.clothes.entity.Category;
import com.wearly.global.common.entity.Style;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class ClothesAnalyzeResponse {

    private String imageKey;
    private String imageUrl;

    private Category category;

    private Style style;

    private Integer colorH;
    private Integer colorS;
    private Integer colorV;

    private String brand;
    private String name;
    private String material;

    @JsonIgnore
    private List<String> searchKeywords;

    private Integer thickness;

    private Double cloValue;
}
