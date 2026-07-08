package com.wearly.domain.outfit.repository;

import com.wearly.domain.outfit.entity.OutfitItems;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OutfitItemsRepository extends JpaRepository<OutfitItems, Long> {

    List<OutfitItems> findByOutfits_Id(Long outfitId);

    void deleteByOutfits_Id(Long outfitId);
}
