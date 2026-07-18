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

    List<Clothes> findByUser(User user);

    List<Clothes> findByUser_Id(Long userId);

    List<Clothes> findByUser_IdAndCategory(Long userId, Category category);

    Slice<Clothes> findByUser_Id(Long userId, Pageable pageable);

    Slice<Clothes> findByUser_IdAndCategory(
            Long userId,
            Category category,
            Pageable pageable
    );

    Slice<Clothes> findByUser_IdAndStyle(
            Long userId,
            Style style,
            Pageable pageable
    );

    Slice<Clothes> findByUser_IdAndCategoryAndStyle(
            Long userId,
            Category category,
            Style style,
            Pageable pageable
    );

    Optional<Clothes> findByIdAndUser_Id(Long id, Long userId);

    List<Clothes> findAllByIdInAndUser_Id(
            Collection<Long> ids,
            Long userId
    );
}
