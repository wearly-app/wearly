package com.wearly.domain.outfit.repository;

import com.wearly.domain.outfit.entity.OutfitHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface OutfitHistoryRepository extends JpaRepository<OutfitHistory, Long> {

    List<OutfitHistory> findByUser_Id(Long userId);

    List<OutfitHistory> findByUser_IdAndWornDateBetween(
            Long userId,
            LocalDate startDate,
            LocalDate endDate
    );

    List<OutfitHistory> findByOutfits_Id(Long outfitId);

    boolean existsByOutfits_IdAndWornDate(
            Long outfitId,
            LocalDate wornDate
    );
}
