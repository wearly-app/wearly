package com.wearly.domain.outfit.repository;

import com.wearly.domain.outfit.entity.Outfits;
import com.wearly.global.common.entity.Style;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface OutfitRepository extends JpaRepository<Outfits, Long> {

    List<Outfits> findByUser_Id(Long userId);

    List<Outfits> findByUser_IdAndStyle(Long userId, Style style);

    List<Outfits> findByUser_IdAndIsFavoriteTrue(Long userId);

    Optional<Outfits> findByIdAndUser_Id(Long id, Long userId);
}
