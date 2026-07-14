package com.wearly.domain.outfit.repository;

import com.wearly.domain.outfit.entity.OutfitItems;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.Collection;
import java.util.List;

public interface OutfitItemsRepository extends JpaRepository<OutfitItems, Long> {

    List<OutfitItems> findByOutfits_Id(Long outfitId);

    @Modifying(flushAutomatically = true)
    @Query("""
    DELETE FROM OutfitItems item
    WHERE item.outfits.id = :outfitId
    """)
    void deleteByOutfits_Id(Long outfitId);

    @EntityGraph(attributePaths = "clothes")
    List<OutfitItems> findByOutfits_IdIn(Collection<Long> outfitIds);
}
