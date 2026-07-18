package com.wearly.domain.user.dto.response;

import com.wearly.domain.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserResponse {

    private Long id;
    private String kakaoId;
    private String name;
    private String email;

    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getKakaoId(),
                user.getName(),
                user.getEmail()
        );
    }
}
