package com.wearly.domain.outfit.service;

import com.wearly.domain.clothes.entity.Clothes;
import com.wearly.domain.clothes.repository.ClothesRepository;
import com.wearly.domain.outfit.dto.request.OutfitCreateRequest;
import com.wearly.domain.outfit.dto.request.OutfitUpdateRequest;
import com.wearly.domain.outfit.dto.response.OutfitClothesResponse;
import com.wearly.domain.outfit.dto.response.OutfitFavoriteResponse;
import com.wearly.domain.outfit.dto.response.OutfitResponse;
import com.wearly.domain.outfit.entity.OutfitItems;
import com.wearly.domain.outfit.entity.Outfits;
import com.wearly.domain.outfit.exception.OutfitErrorCode;
import com.wearly.domain.outfit.exception.OutfitException;
import com.wearly.domain.outfit.repository.OutfitItemsRepository;
import com.wearly.domain.outfit.repository.OutfitRepository;
import com.wearly.domain.user.entity.User;
import com.wearly.domain.user.exception.UserErrorCode;
import com.wearly.domain.user.exception.UserException;
import com.wearly.domain.user.repository.UserRepository;
import com.wearly.global.common.response.SliceResponse;
import com.wearly.infra.s3.S3ImageStorage;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OutfitService {

    private final ClothesRepository clothesRepository;
    private final OutfitRepository outfitRepository;
    private final OutfitItemsRepository outfitItemsRepository;
    private final UserRepository userRepository;
    private final S3ImageStorage s3ImageStorage;

    @Transactional
    public OutfitResponse createOutfit(
            Long userId,
            OutfitCreateRequest request
    ) {
        User user = getUser(userId);

        List<Long> clothesIds = request.getClothesIds();
        Set<Long> uniqueClothesIds = new HashSet<>(clothesIds);

        if (uniqueClothesIds.size() != clothesIds.size()) {
            throw new OutfitException(OutfitErrorCode.DUPLICATE_CLOTHES);
        }

        List<Clothes> clothesList = clothesRepository
                .findAllByIdInAndUser_IdAndDeletedAtIsNull(
                        uniqueClothesIds,
                        userId
                );

        if (clothesList.size() != uniqueClothesIds.size()) {
            throw new OutfitException(
                    OutfitErrorCode.OUTFIT_CLOTHES_NOT_FOUND
            );
        }

        Outfits outfit = Outfits.create(
                user,
                request.getName(),
                request.getStyle()
        );

        Outfits savedOutfit = outfitRepository.save(outfit);

        List<OutfitItems> outfitItems = clothesList.stream()
                .map(clothes -> OutfitItems.create(
                        savedOutfit,
                        clothes
                ))
                .toList();

        outfitItemsRepository.saveAll(outfitItems);

        List<OutfitClothesResponse> clothesResponses = clothesList
                .stream()
                .map(clothes -> OutfitClothesResponse.from(
                        clothes,
                        s3ImageStorage.getUrl(clothes.getImageKey())
                ))
                .toList();

        return OutfitResponse.from(
                savedOutfit,
                clothesResponses
        );
    }

    public OutfitResponse getOutfit(Long userId, Long outfitId) {
        Outfits outfit = outfitRepository
                .findByIdAndUser_IdAndDeletedAtIsNull(outfitId, userId)
                .orElseThrow(() ->
                        new OutfitException(OutfitErrorCode.OUTFIT_NOT_FOUND)
                );

        List<OutfitItems> outfitItems =
                outfitItemsRepository.findByOutfits_Id(outfitId);

        List<OutfitClothesResponse> clothesResponses =
                outfitItems.stream()
                        .map(OutfitItems::getClothes)
                        .map(clothes -> OutfitClothesResponse.from(
                                clothes,
                                s3ImageStorage.getUrl(clothes.getImageKey())
                        ))
                        .toList();

        return OutfitResponse.from(outfit, clothesResponses);
    }

    public SliceResponse<OutfitResponse> getOutfits(
            Long userId,
            Boolean favorite,
            int page,
            int size
    ) {
        Pageable pageable = PageRequest.of(
                page,
                size,
                Sort.by(Sort.Direction.DESC, "createdAt")
        );

        Slice<Outfits> outfitSlice;

        if (favorite == null) {
            outfitSlice = outfitRepository
                    .findByUser_IdAndDeletedAtIsNull(userId, pageable);
        } else {
            outfitSlice = outfitRepository
                    .findByUser_IdAndIsFavoriteAndDeletedAtIsNull(
                            userId,
                            favorite,
                            pageable
                    );
        }

        List<Outfits> outfits = outfitSlice.getContent();

        if (outfits.isEmpty()) {
            return SliceResponse.of(List.of(), outfitSlice);
        }

        List<Long> outfitIds = outfits.stream()
                .map(Outfits::getId)
                .toList();

        Map<Long, List<OutfitItems>> itemsByOutfitId =
                outfitItemsRepository
                        .findByOutfits_IdIn(outfitIds)
                        .stream()
                        .collect(Collectors.groupingBy(
                                item -> item.getOutfits().getId()
                        ));

        List<OutfitResponse> responses = outfits.stream()
                .map(outfit -> {
                    List<OutfitClothesResponse> clothesResponses =
                            itemsByOutfitId
                                    .getOrDefault(
                                            outfit.getId(),
                                            List.of()
                                    )
                                    .stream()
                                    .map(OutfitItems::getClothes)
                                    .map(clothes ->
                                            OutfitClothesResponse.from(
                                                    clothes,
                                                    s3ImageStorage.getUrl(
                                                            clothes.getImageKey()
                                                    )
                                            )
                                    )
                                    .toList();

                    return OutfitResponse.from(
                            outfit,
                            clothesResponses
                    );
                })
                .toList();

        return SliceResponse.of(responses, outfitSlice);
    }

    @Transactional
    public OutfitResponse updateOutfit(
            Long userId,
            Long outfitId,
            OutfitUpdateRequest request
    ) {
        Outfits outfit = outfitRepository
                .findByIdAndUser_IdAndDeletedAtIsNull(outfitId, userId)
                .orElseThrow(() ->
                        new OutfitException(OutfitErrorCode.OUTFIT_NOT_FOUND)
                );

        if (request.getName() != null && request.getName().isBlank()) {
            throw new OutfitException(
                    OutfitErrorCode.OUTFIT_NAME_INVALID
            );
        }

        outfit.update(
                request.getName(),
                request.getStyle()
        );

        if (request.getClothesIds() != null) {
            replaceOutfitItems(
                    userId,
                    outfit,
                    request.getClothesIds()
            );
        }

        List<OutfitItems> outfitItems =
                outfitItemsRepository.findByOutfits_Id(outfitId);

        List<OutfitClothesResponse> clothesResponses =
                outfitItems.stream()
                        .map(OutfitItems::getClothes)
                        .map(clothes -> OutfitClothesResponse.from(
                                clothes,
                                s3ImageStorage.getUrl(clothes.getImageKey())
                        ))
                        .toList();

        return OutfitResponse.from(outfit, clothesResponses);
    }

    @Transactional
    public void deleteOutfit(Long userId, Long outfitId) {
        Outfits outfit = outfitRepository
                .findByIdAndUser_IdAndDeletedAtIsNull(outfitId, userId)
                .orElseThrow(() ->
                        new OutfitException(OutfitErrorCode.OUTFIT_NOT_FOUND)
                );

        outfit.softDelete();
    }

    @Transactional
    public OutfitFavoriteResponse toggleFavorite(
            Long userId,
            Long outfitId
    ) {
        Outfits outfit = outfitRepository
                .findByIdAndUser_IdAndDeletedAtIsNull(outfitId, userId)
                .orElseThrow(() ->
                        new OutfitException(OutfitErrorCode.OUTFIT_NOT_FOUND)
                );

        outfit.toggleFavorite();

        return OutfitFavoriteResponse.from(outfit);
    }

    private User getUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() ->
                        new UserException(UserErrorCode.USER_NOT_FOUND)
                );
    }

    private void replaceOutfitItems(
            Long userId,
            Outfits outfit,
            List<Long> clothesIds
    ) {
        Set<Long> uniqueClothesIds = new HashSet<>(clothesIds);

        if (uniqueClothesIds.size() != clothesIds.size()) {
            throw new OutfitException(
                    OutfitErrorCode.DUPLICATE_CLOTHES
            );
        }

        List<Clothes> clothesList =
                clothesRepository
                        .findAllByIdInAndUser_IdAndDeletedAtIsNull(
                                uniqueClothesIds,
                                userId
                        );

        if (clothesList.size() != uniqueClothesIds.size()) {
            throw new OutfitException(
                    OutfitErrorCode.OUTFIT_CLOTHES_NOT_FOUND
            );
        }

        outfitItemsRepository.deleteByOutfits_Id(outfit.getId());

        List<OutfitItems> newItems = clothesList.stream()
                .map(clothes -> OutfitItems.create(
                        outfit,
                        clothes
                ))
                .toList();

        outfitItemsRepository.saveAll(newItems);
    }
}
