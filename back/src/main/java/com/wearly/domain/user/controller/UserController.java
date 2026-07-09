package com.wearly.domain.user.controller;

import com.wearly.domain.user.dto.response.UserResponse;
import com.wearly.domain.user.entity.User;
import com.wearly.domain.user.exception.UserErrorCode;
import com.wearly.domain.user.exception.UserException;
import com.wearly.domain.user.repository.UserRepository;
import com.wearly.global.security.WearlyUserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/me")
    public ResponseEntity<UserResponse> getMyProfile(
            @AuthenticationPrincipal WearlyUserPrincipal principal
    ) {
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new UserException(UserErrorCode.USER_NOT_FOUND));

        return ResponseEntity.ok(UserResponse.from(user));
    }
}
