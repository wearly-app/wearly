package com.wearly.domain.clothes.service;

import com.wearly.domain.clothes.dto.request.ClothesCreateRequest;
import com.wearly.domain.clothes.dto.request.ClothesUpdateRequest;
import com.wearly.domain.clothes.dto.response.ClothesResponse;
import com.wearly.domain.clothes.dto.response.ClothesWearResponse;
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
import com.wearly.global.common.response.SliceResponse;
import com.wearly.infra.s3.S3ImageStorage;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ClothesService {

    private final ClothesRepository clothesRepository;
    private final UserRepository userRepository;
    private final S3ImageStorage s3ImageStorage;

    @Transactional
    public ClothesResponse createClothes(Long userId, ClothesCreateRequest request) {
        User user = getUser(userId);

        Clothes clothes = Clothes.create(
                user,
                request.getName(),
                request.getCategory(),
                request.getStyle(),
                request.getImageKey(),
                request.getColorH(),
                request.getColorS(),
                request.getColorV(),
                request.getBrand(),
                request.getMaterial(),
                request.getThickness(),
                request.getCloValue()
        );

        Clothes savedClothes = clothesRepository.save(clothes);
        String imageUrl = s3ImageStorage.getUrl(savedClothes.getImageKey());

        return ClothesResponse.from(clothes, imageUrl);
    }

    public SliceResponse<ClothesResponse> getClothesList(
            Long userId,
            Category category,
            Style style,
            int page,
            int size
    ) {
        Pageable pageable = PageRequest.of(
                page,
                size,
                Sort.by(Sort.Direction.DESC, "createdAt")
        );

        Slice<Clothes> clothesSlice = getClothesSlice(
                userId,
                category,
                style,
                pageable
        );

        List<ClothesResponse> content = clothesSlice.getContent().stream()
                .map(c -> ClothesResponse.from(c, s3ImageStorage.getUrl(c.getImageKey())))
                .toList();

        return SliceResponse.of(content, clothesSlice);
    }

    public ClothesResponse getClothes(Long userId, Long clothesId) {
        Clothes clothes = getClothesByIdAndUserId(clothesId, userId);
        String imageUrl = s3ImageStorage.getUrl(clothes.getImageKey());
        return ClothesResponse.from(clothes, imageUrl);
    }

    @Transactional
    public ClothesResponse updateClothes(Long userId, Long clothesId, ClothesUpdateRequest request) {
        Clothes clothes = getClothesByIdAndUserId(clothesId, userId);

        clothes.update(
                request.getName(),
                request.getCategory(),
                request.getStyle(),
                request.getImageKey(),
                request.getColorH(),
                request.getColorS(),
                request.getColorV(),
                request.getBrand(),
                request.getMaterial(),
                request.getThickness(),
                request.getCloValue()
        );

        String imageUrl = s3ImageStorage.getUrl(clothes.getImageKey());

        return ClothesResponse.from(clothes, imageUrl);
    }

    @Transactional
    public void deleteClothes(Long userId, Long clothesId) {
        Clothes clothes = getClothesByIdAndUserId(clothesId, userId);

        clothes.softDelete();
    }

    @Transactional
    public ClothesWearResponse wearClothes(Long userId, Long clothesId) {
        Clothes clothes = getClothesByIdAndUserId(clothesId, userId);

        clothes.recordWear(LocalDate.now());

        return ClothesWearResponse.from(clothes);
    }

    private User getUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new UserException(UserErrorCode.USER_NOT_FOUND));
    }

    private Clothes getClothesByIdAndUserId(Long clothesId, Long userId) {
        return clothesRepository
                .findByIdAndUser_IdAndDeletedAtIsNull(
                        clothesId,
                        userId
                )
                .orElseThrow(() -> new ClothesException(ClothesErrorCode.CLOTHES_NOT_FOUND));
    }

    private Slice<Clothes> getClothesSlice(
            Long userId,
            Category category,
            Style style,
            Pageable pageable
    ) {
        if (category != null && style != null) {
            return clothesRepository
                    .findByUser_IdAndCategoryAndStyleAndDeletedAtIsNull(
                            userId,
                            category,
                            style,
                            pageable
                    );
        }

        if (category != null) {
            return clothesRepository
                    .findByUser_IdAndCategoryAndDeletedAtIsNull(
                            userId,
                            category,
                            pageable
                    );
        }

        if (style != null) {
            return clothesRepository
                    .findByUser_IdAndStyleAndDeletedAtIsNull(
                            userId,
                            style,
                            pageable
                    );
        }

        return clothesRepository.findByUser_IdAndDeletedAtIsNull(
                userId,
                pageable
        );
    }
}
