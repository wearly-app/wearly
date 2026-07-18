package com.wearly.domain.outfit.dto.request;

import com.wearly.global.common.entity.Style;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class OutfitUpdateRequest {

    @Size(min = 1, max = 50)
    private String name;

    private Style style;

    @Size(min = 1, max = 10)
    private List<@NotNull Long> clothesIds;
}
