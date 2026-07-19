package com.wearly.domain.outfit.service;

import com.wearly.domain.clothes.dto.response.ClothesWearHistoryResponse;
import com.wearly.domain.clothes.exception.ClothesErrorCode;
import com.wearly.domain.clothes.exception.ClothesException;
import com.wearly.domain.clothes.repository.ClothesRepository;
import com.wearly.domain.outfit.dto.response.OutfitWearResponse;
import com.wearly.domain.outfit.entity.OutfitHistory;
import com.wearly.domain.outfit.entity.OutfitHistoryItem;
import com.wearly.domain.outfit.entity.OutfitItems;
import com.wearly.domain.outfit.entity.Outfits;
import com.wearly.domain.outfit.exception.OutfitErrorCode;
import com.wearly.domain.outfit.exception.OutfitException;
import com.wearly.domain.outfit.repository.OutfitHistoryItemRepository;
import com.wearly.domain.outfit.repository.OutfitHistoryRepository;
import com.wearly.domain.outfit.repository.OutfitItemsRepository;
import com.wearly.domain.outfit.repository.OutfitRepository;
import com.wearly.global.common.response.SliceResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OutfitHistoryService {

    private static final ZoneId KOREA_ZONE_ID = ZoneId.of("Asia/Seoul");

    private final OutfitRepository outfitRepository;
    private final OutfitItemsRepository outfitItemsRepository;
    private final OutfitHistoryRepository outfitHistoryRepository;
    private final OutfitHistoryItemRepository outfitHistoryItemRepository;
    private final ClothesRepository clothesRepository;

    @Transactional
    public OutfitWearResponse wearOutfit(Long userId, Long outfitId) {
        Outfits outfit = outfitRepository
                .findByIdAndUser_IdAndDeletedAtIsNull(outfitId, userId)
                .orElseThrow(() -> new OutfitException(OutfitErrorCode.OUTFIT_NOT_FOUND));

        LocalDate wornDate = LocalDate.now(KOREA_ZONE_ID);

        validateNotWornToday(outfitId, wornDate);

        List<OutfitItems> outfitItems = outfitItemsRepository.findByOutfits_Id(outfitId);

        if (outfitItems.isEmpty()) {
            throw new OutfitException(OutfitErrorCode.OUTFIT_HAS_NO_CLOTHES);
        }

        OutfitHistory history = OutfitHistory.create(
                outfit.getUser(),
                outfit,
                wornDate
        );

        OutfitHistory savedHistory = saveHistory(history);

        List<OutfitHistoryItem> historyItems = outfitItems.stream()
                .map(OutfitItems::getClothes)
                .map(clothes -> OutfitHistoryItem.create(savedHistory, clothes))
                .toList();

        outfitHistoryItemRepository.saveAll(historyItems);

        outfitItems.stream()
                .map(OutfitItems::getClothes)
                .forEach(clothes -> clothes.recordWear(wornDate));

        List<Long> clothesIds = outfitItems.stream()
                .map(OutfitItems::getClothes)
                .map(clothes -> clothes.getId())
                .toList();

        return OutfitWearResponse.from(savedHistory, clothesIds);
    }

    public SliceResponse<ClothesWearHistoryResponse> getClothesWearHistory(
            Long userId,
            Long clothesId,
            int page,
            int size
    ) {
        clothesRepository
                .findByIdAndUser_IdAndDeletedAtIsNull(clothesId, userId)
                .orElseThrow(() -> new ClothesException(ClothesErrorCode.CLOTHES_NOT_FOUND));

        Pageable pageable = PageRequest.of(page, size);

        Slice<OutfitHistoryItem> historySlice = outfitHistoryItemRepository
                .findByClothes_IdOrderByOutfitHistory_WornDateDescOutfitHistory_IdDesc(
                        clothesId,
                        pageable
                );

        List<ClothesWearHistoryResponse> responses = historySlice.getContent().stream()
                .map(ClothesWearHistoryResponse::from)
                .toList();

        return SliceResponse.of(responses, historySlice);
    }

    private void validateNotWornToday(Long outfitId, LocalDate wornDate) {
        boolean alreadyWorn = outfitHistoryRepository.existsByOutfits_IdAndWornDate(
                outfitId,
                wornDate
        );

        if (alreadyWorn) {
            throw new OutfitException(OutfitErrorCode.OUTFIT_ALREADY_WORN_TODAY);
        }
    }

    private OutfitHistory saveHistory(OutfitHistory history) {
        try {
            return outfitHistoryRepository.saveAndFlush(history);
        } catch (DataIntegrityViolationException exception) {
            throw new OutfitException(OutfitErrorCode.OUTFIT_ALREADY_WORN_TODAY);
        }
    }
}
