package com.wearly.domain.clothes.entity;

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

import java.time.LocalDate;

@Entity
@Table(name = "clothes")
@Getter
@NoArgsConstructor
public class Clothes extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Category category;

    @Enumerated(EnumType.STRING)
    private Style style;

    @Column(length = 255)
    private String imageUrl;

    @Column(columnDefinition = "SMALLINT")
    private Integer colorH;

    @Column(columnDefinition = "SMALLINT")
    private Integer colorS;

    @Column(columnDefinition = "SMALLINT")
    private Integer colorV;

    @Column(length = 50)
    private String brand;

    @Column(length = 50)
    private String material;

    @Column(columnDefinition = "SMALLINT")
    private Integer thickness;

    private Double cloValue;

    @Column(nullable = false)
    private Integer wearCount;

    private LocalDate lastWornAt;
}
