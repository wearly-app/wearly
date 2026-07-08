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
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "outfit_items")
@Getter
@NoArgsConstructor
public class OutfitItems {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "outfit_id", nullable = false)
    private Outfits outfits;


    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cloth_id", nullable = false)
    private Clothes clothes;

}
