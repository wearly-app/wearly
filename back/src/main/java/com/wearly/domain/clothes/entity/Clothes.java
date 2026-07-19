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
import java.time.LocalDateTime;

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

    private LocalDateTime deletedAt;

    public void update(
            Category category,
            Style style,
            String imageUrl,
            Integer colorH,
            Integer colorS,
            Integer colorV,
            String brand,
            String material,
            Integer thickness,
            Double cloValue
    ) {
        if (category != null) {
            this.category = category;
        }
        if (style != null) {
            this.style = style;
        }
        if (imageUrl != null) {
            this.imageUrl = imageUrl;
        }
        if (colorH != null) {
            this.colorH = colorH;
        }
        if (colorS != null) {
            this.colorS = colorS;
        }
        if (colorV != null) {
            this.colorV = colorV;
        }
        if (brand != null) {
            this.brand = brand;
        }
        if (material != null) {
            this.material = material;
        }
        if (thickness != null) {
            this.thickness = thickness;
        }
        if (cloValue != null) {
            this.cloValue = cloValue;
        }
    }

    public static Clothes create(
            User user,
            Category category,
            Style style,
            String imageUrl,
            Integer colorH,
            Integer colorS,
            Integer colorV,
            String brand,
            String material,
            Integer thickness,
            Double cloValue
    ) {
        Clothes clothes = new Clothes();
        clothes.user = user;
        clothes.category = category;
        clothes.style = style;
        clothes.imageUrl = imageUrl;
        clothes.colorH = colorH;
        clothes.colorS = colorS;
        clothes.colorV = colorV;
        clothes.brand = brand;
        clothes.material = material;
        clothes.thickness = thickness;
        clothes.cloValue = cloValue;
        clothes.wearCount = 0;
        return clothes;
    }

    public void recordWear(LocalDate wornDate) {
        this.wearCount += 1;

        if (this.lastWornAt == null ||
                wornDate.isAfter(this.lastWornAt)) {
            this.lastWornAt = wornDate;
        }
    }

    public void softDelete() {
        this.deletedAt = LocalDateTime.now();
    }
}
