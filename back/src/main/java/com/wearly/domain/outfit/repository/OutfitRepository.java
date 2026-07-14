package com.wearly.domain.outfit.repository;

import com.wearly.domain.outfit.entity.Outfits;
import com.wearly.global.common.entity.Style;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface OutfitRepository extends JpaRepository<Outfits, Long> {

    List<Outfits> findByUser_Id(Long userId);

    List<Outfits> findByUser_IdAndStyle(Long userId, Style style);

    List<Outfits> findByUser_IdAndIsFavoriteTrue(Long userId);

    List<Outfits> findByUser_IdAndIsFavoriteFalseOrderByCreatedAtDesc(
            Long userId
    );

    List<Outfits> findByUser_IdAndIsFavoriteTrueOrderByCreatedAtDesc(
            Long userId
    );

    Optional<Outfits> findByIdAndUser_Id(Long id, Long userId);

    List<Outfits> findByUser_IdOrderByCreatedAtDesc(Long userId);

    Slice<Outfits> findByUser_Id(Long userId, Pageable pageable);

    Slice<Outfits> findByUser_IdAndIsFavorite(
            Long userId,
            boolean favorite,
            Pageable pageable
    );
}
