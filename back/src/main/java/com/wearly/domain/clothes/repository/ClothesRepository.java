package com.wearly.domain.clothes.repository;

import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.entity.Clothes;
import com.wearly.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ClothesRepository extends JpaRepository<Clothes, Long> {

    List<Clothes> findByUser(User user);

    List<Clothes> findByUser_Id(Long userId);

    List<Clothes> findByUser_IdAndCategory(Long userId, Category category);

    Optional<Clothes> findByIdAndUser_Id(Long id, Long userId);
}
