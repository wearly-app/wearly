package com.wearly.domain.clothes.controller;

import com.wearly.domain.clothes.dto.request.ClothesCreateRequest;
import com.wearly.domain.clothes.dto.request.ClothesUpdateRequest;
import com.wearly.domain.clothes.dto.response.ClothesResponse;
import com.wearly.domain.clothes.dto.response.ClothesAnalyzeResponse;
import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.service.ClothesService;
import com.wearly.domain.clothes.service.RembgService;
import com.wearly.domain.clothes.service.GeminiApiClient;
import com.wearly.global.common.entity.Style;
import com.wearly.global.security.WearlyUserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.wearly.domain.clothes.service.PythonCrawlerService;
import java.util.List;
import java.util.Map;
import java.io.ByteArrayInputStream;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.awt.Color;

@RestController
@RequestMapping("/api/clothes")
@RequiredArgsConstructor
public class ClothesController {

    private final ClothesService clothesService;
    private final RembgService rembgService;
    private final GeminiApiClient geminiApiClient;
    private final PythonCrawlerService pythonCrawlerService;

    @PostMapping("/analyze")
    public ResponseEntity<ClothesAnalyzeResponse> analyzeClothesImage(
            @RequestPart MultipartFile image
    ) {
        try {
            byte[] originalBytes = image.getBytes();

            byte[] processedBytes = rembgService.removeBackground(originalBytes);

            String base64Image = java.util.Base64.getEncoder().encodeToString(processedBytes);
            String imageUrl = "data:image/png;base64," + base64Image;

            ClothesAnalyzeResponse response = geminiApiClient.analyzeClothingImage(processedBytes, base64Image);

            String brand = response.getBrand();
            String name = "";
            String material = response.getMaterial();
            String productUrl = geminiApiClient.findProductUrl(base64Image, brand != null ? brand : "");
            
            if (productUrl != null && productUrl.startsWith("http")) {
                Map<String, String> pythonCrawled = pythonCrawlerService.crawl(productUrl);
                if (pythonCrawled != null) {
                    if (!pythonCrawled.getOrDefault("name", "").isEmpty()) {
                        brand = pythonCrawled.getOrDefault("brand", "마초");
                        name = pythonCrawled.get("name");
                        material = pythonCrawled.getOrDefault("material", "정보 없음");
                    }
                }
            }
            
            // Extract dominant color locally
            int finalColorH = response.getColorH();
            int finalColorS = response.getColorS();
            int finalColorV = response.getColorV();
            int[] localColor = extractDominantColor(processedBytes);
            if (localColor != null) {
                finalColorH = localColor[0];
                finalColorS = localColor[1];
                finalColorV = localColor[2];
            }
            
            ClothesAnalyzeResponse finalResponse = ClothesAnalyzeResponse.builder()
                    .imageUrl(imageUrl)
                    .category(response.getCategory())
                    .style(response.getStyle())
                    .colorH(finalColorH)
                    .colorS(finalColorS)
                    .colorV(finalColorV)
                    .brand(brand)
                    .name(name)
                    .material(material)
                    .thickness(response.getThickness())
                    .cloValue(response.getCloValue())
                    .build();

            return ResponseEntity.ok(finalResponse);
        } catch (Exception e) {
            throw new RuntimeException("Failed to analyze clothes image", e);
        }
    }

    private int[] extractDominantColor(byte[] imageBytes) {
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (image == null) return null;
            long rSum = 0, gSum = 0, bSum = 0;
            int count = 0;
            for (int y = 0; y < image.getHeight(); y++) {
                for (int x = 0; x < image.getWidth(); x++) {
                    int argb = image.getRGB(x, y);
                    int alpha = (argb >> 24) & 0xff;
                    if (alpha > 50) { 
                        int r = (argb >> 16) & 0xff;
                        int g = (argb >> 8) & 0xff;
                        int b = argb & 0xff;
                        if (r < 240 || g < 240 || b < 240) { 
                            rSum += r;
                            gSum += g;
                            bSum += b;
                            count++;
                        }
                    }
                }
            }
            if (count > 0) {
                int rAvg = (int)(rSum / count);
                int gAvg = (int)(gSum / count);
                int bAvg = (int)(bSum / count);
                float[] hsb = Color.RGBtoHSB(rAvg, gAvg, bAvg, null);
                return new int[]{ (int)(hsb[0] * 360), (int)(hsb[1] * 100), (int)(hsb[2] * 100) };
            }
        } catch (Exception e) {
            // ignore
        }
        return null;
    }

    @PostMapping
    public ResponseEntity<ClothesResponse> createClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @Valid @RequestBody ClothesCreateRequest request
    ) {
        ClothesResponse response = clothesService.createClothes(principal.getUserId(), request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @GetMapping
    public ResponseEntity<List<ClothesResponse>> getClothesList(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @RequestParam(required = false) Category category,
            @RequestParam(required = false) Style style
    ) {
        List<ClothesResponse> response = clothesService.getClothesList(
                principal.getUserId(),
                category,
                style);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClothesResponse> getClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        ClothesResponse response = clothesService.getClothes(principal.getUserId(), id);

        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ClothesResponse> updateClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody ClothesUpdateRequest request
    ) {
        ClothesResponse response = clothesService.updateClothes(principal.getUserId(), id, request);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        clothesService.deleteClothes(principal.getUserId(), id);

        return ResponseEntity.noContent().build();
    }
}
