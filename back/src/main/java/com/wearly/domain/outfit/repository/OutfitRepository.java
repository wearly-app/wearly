package com.wearly.domain.outfit.repository;

import com.wearly.domain.outfit.entity.Outfits;
import com.wearly.global.common.entity.Style;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface OutfitRepository extends JpaRepository<Outfits, Long> {

    List<Outfits> findByUser_IdAndDeletedAtIsNull(Long userId);

    List<Outfits> findByUser_IdAndStyleAndDeletedAtIsNull(
            Long userId,
            Style style
    );

    List<Outfits> findByUser_IdAndIsFavoriteTrueAndDeletedAtIsNull(
            Long userId
    );

    List<Outfits> findByUser_IdAndIsFavoriteFalseAndDeletedAtIsNullOrderByCreatedAtDesc(
            Long userId
    );

    List<Outfits> findByUser_IdAndIsFavoriteTrueAndDeletedAtIsNullOrderByCreatedAtDesc(
            Long userId
    );

    Optional<Outfits> findByIdAndUser_IdAndDeletedAtIsNull(
            Long id,
            Long userId
    );

    List<Outfits> findByUser_IdAndDeletedAtIsNullOrderByCreatedAtDesc(
            Long userId
    );

    Slice<Outfits> findByUser_IdAndDeletedAtIsNull(
            Long userId,
            Pageable pageable
    );

    Slice<Outfits> findByUser_IdAndIsFavoriteAndDeletedAtIsNull(
            Long userId,
            boolean favorite,
            Pageable pageable
    );
}
