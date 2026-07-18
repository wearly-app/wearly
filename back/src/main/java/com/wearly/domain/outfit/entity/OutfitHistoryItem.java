package com.wearly.domain.outfit.entity;

import com.wearly.domain.clothes.entity.Clothes;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(
        name = "outfit_history_items",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_history_items_history_clothes",
                        columnNames = {
                                "outfit_history_id",
                                "cloth_id"
                        }
                )
        }
)
@Getter
@NoArgsConstructor
public class OutfitHistoryItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "outfit_history_id", nullable = false)
    private OutfitHistory outfitHistory;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cloth_id", nullable = false)
    private Clothes clothes;

    public static OutfitHistoryItem create(
            OutfitHistory outfitHistory,
            Clothes clothes
    ) {
        OutfitHistoryItem item = new OutfitHistoryItem();
        item.outfitHistory = outfitHistory;
        item.clothes = clothes;
        return item;
    }
}
