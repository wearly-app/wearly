package com.wearly.domain.clothes.dto.request;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.global.common.entity.Style;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class ClothesCreateRequest {

    @NotNull
    private Category category;

    private String name;

    private Style style;

    @NotBlank
    private String imageKey;

    private Integer colorH;
    private Integer colorS;
    private Integer colorV;

    private String brand;

    private String material;

    private Integer thickness;

    private Double cloValue;
}
