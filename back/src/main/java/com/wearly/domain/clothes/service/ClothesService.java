package com.wearly.domain.clothes.service;

import com.wearly.domain.clothes.dto.request.ClothesCreateRequest;
import com.wearly.domain.clothes.dto.request.ClothesUpdateRequest;
import com.wearly.domain.clothes.dto.response.ClothesResponse;
import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.entity.Clothes;
import com.wearly.domain.clothes.exception.ClothesErrorCode;
import com.wearly.domain.clothes.exception.ClothesException;
import com.wearly.domain.clothes.repository.ClothesRepository;
import com.wearly.domain.user.entity.User;
import com.wearly.domain.user.exception.UserErrorCode;
import com.wearly.domain.user.exception.UserException;
import com.wearly.domain.user.repository.UserRepository;
import com.wearly.global.common.entity.Style;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ClothesService {

    private final ClothesRepository clothesRepository;
    private final UserRepository userRepository;

    @Transactional
    public ClothesResponse createClothes(Long userId, ClothesCreateRequest request) {
        User user = getUser(userId);

        Clothes clothes = Clothes.create(
                user,
                request.getCategory(),
                request.getStyle(),
                request.getImageUrl(),
                request.getColorH(),
                request.getColorS(),
                request.getColorV(),
                request.getBrand(),
                request.getMaterial(),
                request.getThickness(),
                request.getCloValue()
        );

        Clothes savedClothes = clothesRepository.save(clothes);

        return ClothesResponse.from(clothes);
    }

    public List<ClothesResponse> getClothesList(Long userId, Category category, Style style) {
        List<Clothes> clothesList = clothesRepository.findByUser_Id(userId);

        return clothesList.stream()
                .filter(clothes -> category == null || clothes.getCategory() == category)
                .filter(clothes -> style == null || clothes.getStyle() == style)
                .map(ClothesResponse::from)
                .toList();
    }

    public ClothesResponse getClothes(Long userId, Long clothesId) {
        Clothes clothes = getClothesByIdAndUserId(clothesId, userId);

        return ClothesResponse.from(clothes);
    }

    @Transactional
    public ClothesResponse updateClothes(Long userId, Long clothesId, ClothesUpdateRequest request) {
        Clothes clothes = getClothesByIdAndUserId(clothesId, userId);

        clothes.update(
                request.getCategory(),
                request.getStyle(),
                request.getImageUrl(),
                request.getColorH(),
                request.getColorS(),
                request.getColorV(),
                request.getBrand(),
                request.getMaterial(),
                request.getThickness(),
                request.getCloValue()
        );

        return ClothesResponse.from(clothes);
    }

    @Transactional
    public void deleteClothes(Long userId, Long clothesId) {
        Clothes clothes = getClothesByIdAndUserId(clothesId, userId);

        clothesRepository.delete(clothes);
    }

    private User getUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new UserException(UserErrorCode.USER_NOT_FOUND));
    }

    private Clothes getClothesByIdAndUserId(Long clothesId, Long userId) {
        return clothesRepository.findByIdAndUser_Id(clothesId, userId)
                .orElseThrow(() -> new ClothesException(ClothesErrorCode.CLOTHES_NOT_FOUND));
    }
}
