package com.wearly.domain.outfit.entity;

import com.wearly.domain.user.entity.User;
import com.wearly.global.common.entity.BaseEntity;
import com.wearly.global.common.entity.Style;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name = "outfits")
@Getter
@NoArgsConstructor
public class Outfits extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(length = 50)
    private String name;

    @Enumerated(EnumType.STRING)
    private Style style;

    private String thumbnailUrl;

    private Boolean isFavorite;
}
