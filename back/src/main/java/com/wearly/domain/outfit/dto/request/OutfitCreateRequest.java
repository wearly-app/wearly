package com.wearly.domain.outfit.dto.request;

import com.wearly.global.common.entity.Style;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class OutfitCreateRequest {

    @NotBlank
    @Size(max = 50)
    private String name;

    private Style style;

    @NotEmpty
    @Size(max = 10)
    private List<@NotNull Long> clothesIds;
}
