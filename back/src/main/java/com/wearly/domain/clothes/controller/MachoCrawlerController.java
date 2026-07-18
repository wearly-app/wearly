package com.wearly.domain.clothes.controller;

import com.wearly.domain.clothes.service.MachoCrawlerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 기존 ClothesController와 완벽히 격리된 크롤러 전용 컨트롤러
 */
@RestController
@RequestMapping("/api/clothes")
@RequiredArgsConstructor
public class MachoCrawlerController {

    private final MachoCrawlerService machoCrawlerService;

    @PostMapping("/crawl")
    public ResponseEntity<Map<String, String>> crawlClothesInfo(
            @RequestBody Map<String, String> request
    ) {
        String url = request.get("url");
        if (url == null || url.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(machoCrawlerService.crawlProductInfo(url));
    }
}
