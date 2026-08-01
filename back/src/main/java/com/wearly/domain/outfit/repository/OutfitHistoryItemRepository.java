package com.wearly.domain.outfit.repository;

import com.wearly.domain.outfit.entity.OutfitHistoryItem;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OutfitHistoryItemRepository
        extends JpaRepository<OutfitHistoryItem, Long> {

    @EntityGraph(attributePaths = {
            "outfitHistory",
            "outfitHistory.outfits"
    })
    Slice<OutfitHistoryItem> findByClothes_IdOrderByOutfitHistory_WornDateDescOutfitHistory_IdDesc(
            Long clothesId,
            Pageable pageable
    );

    @EntityGraph(attributePaths = {"clothes"})
    List<OutfitHistoryItem> findByOutfitHistory_IdIn(List<Long> outfitHistoryIds);
}
