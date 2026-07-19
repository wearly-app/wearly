package com.wearly.domain.clothes.dto.response;

public record ProductSearchCandidate(
        String name,
        String productUrl,
        double similarity
) {
}
