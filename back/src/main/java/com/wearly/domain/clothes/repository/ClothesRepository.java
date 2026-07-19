package com.wearly.domain.clothes.repository;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.entity.Clothes;
import com.wearly.domain.user.entity.User;
import com.wearly.global.common.entity.Style;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface ClothesRepository extends JpaRepository<Clothes, Long> {

    List<Clothes> findByUserAndDeletedAtIsNull(User user);

    List<Clothes> findByUser_IdAndDeletedAtIsNull(Long userId);

    List<Clothes> findByUser_IdAndCategoryAndDeletedAtIsNull(
            Long userId,
            Category category
    );

    Slice<Clothes> findByUser_IdAndDeletedAtIsNull(
            Long userId,
            Pageable pageable
    );

    Slice<Clothes> findByUser_IdAndCategoryAndDeletedAtIsNull(
            Long userId,
            Category category,
            Pageable pageable
    );

    Slice<Clothes> findByUser_IdAndStyleAndDeletedAtIsNull(
            Long userId,
            Style style,
            Pageable pageable
    );

    Slice<Clothes> findByUser_IdAndCategoryAndStyleAndDeletedAtIsNull(
            Long userId,
            Category category,
            Style style,
            Pageable pageable
    );

    Optional<Clothes> findByIdAndUser_IdAndDeletedAtIsNull(
            Long id,
            Long userId
    );

    List<Clothes> findAllByIdInAndUser_IdAndDeletedAtIsNull(
            Collection<Long> ids,
            Long userId
    );
}
