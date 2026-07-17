package com.wearly.domain.outfit.entity;

import com.wearly.domain.user.entity.User;
import com.wearly.global.common.entity.BaseEntity;
import jakarta.persistence.Column;
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

import java.time.LocalDate;

@Entity
@Table(
        name = "outfit_history",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_outfit_history_user_outfit_date",
                        columnNames = {
                                "user_id",
                                "outfit_id",
                                "worn_date"
                        }
                )
        }
)
@Getter
@NoArgsConstructor
public class OutfitHistory extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "outfit_id", nullable = false)
    private Outfits outfits;

    @Column(name = "worn_date", nullable = false)
    private LocalDate wornDate;

    public static OutfitHistory create(
            User user,
            Outfits outfit,
            LocalDate wornDate
    ) {
        OutfitHistory history = new OutfitHistory();
        history.user = user;
        history.outfits = outfit;
        history.wornDate = wornDate;
        return history;
    }
}
