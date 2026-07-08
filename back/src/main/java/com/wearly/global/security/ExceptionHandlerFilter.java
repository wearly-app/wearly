package com.wearly.global.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.wearly.auth.exception.AuthErrorCode;
import com.wearly.auth.exception.AuthException;
import com.wearly.global.exception.ErrorCode;
import com.wearly.global.exception.ErrorResponse;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Slf4j
public class ExceptionHandlerFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        try {
            filterChain.doFilter(request, response);
        } catch (AuthException e) {
            setErrorResponse(response, e.getErrorCode());
        } catch (ExpiredJwtException e) {
            setErrorResponse(response, AuthErrorCode.ACCESS_TOKEN_EXPIRED);
        } catch (JwtException | IllegalArgumentException e) {
            setErrorResponse(response, AuthErrorCode.INVALID_ACCESS_TOKEN);
        }
    }

    private void setErrorResponse(
            HttpServletResponse response,
            ErrorCode errorCode
    ) {
        ObjectMapper objectMapper = new ObjectMapper();
        response.setStatus(errorCode.getHttpStatus().value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");

        ErrorResponse errorResponse = new ErrorResponse(errorCode.getMessage());

        try {
            response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
        } catch (IOException e) {
            log.error("JWT 예외 응답 작성 중 오류 발생", e);
        }
    }
}