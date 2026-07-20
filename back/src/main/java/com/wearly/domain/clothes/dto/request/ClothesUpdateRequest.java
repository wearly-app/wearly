package com.wearly.domain.clothes.dto.request;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.global.common.entity.Style;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class ClothesUpdateRequest {

    @Size(max = 100)
    private String name;

    private Category category;

    private Style style;

    private String imageKey;

    private Integer colorH;
    private Integer colorS;
    private Integer colorV;

    private String brand;

    private String material;

    private Integer thickness;

    private Double cloValue;
}
