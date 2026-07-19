package com.wearly.domain.clothes.controller;

import com.wearly.domain.clothes.dto.request.ClothesCreateRequest;
import com.wearly.domain.clothes.dto.request.ClothesUpdateRequest;
import com.wearly.domain.clothes.dto.response.ClothesAnalyzeResponse;
import com.wearly.domain.clothes.dto.response.ClothesResponse;
import com.wearly.domain.clothes.dto.response.ClothesThermalAnalysis;
import com.wearly.domain.clothes.dto.response.ClothesWearHistoryResponse;
import com.wearly.domain.clothes.dto.response.ProductSearchCandidate;
import com.wearly.domain.clothes.entity.Category;
import com.wearly.domain.clothes.service.ClothesService;
import com.wearly.domain.clothes.service.GeminiApiClient;
import com.wearly.domain.clothes.service.ProductCrawlerService;
import com.wearly.domain.clothes.service.RembgService;
import com.wearly.domain.clothes.service.UniqloProductSearchService;
import com.wearly.domain.outfit.service.OutfitHistoryService;
import com.wearly.global.common.entity.Style;
import com.wearly.global.common.response.SliceResponse;
import com.wearly.global.config.OpenApiConfig;
import com.wearly.global.security.WearlyUserPrincipal;
import com.wearly.infra.s3.S3ImageStorage;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
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

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.util.Base64;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/clothes")
@RequiredArgsConstructor
@Validated
@Tag(name = "Clothes", description = "옷 등록 및 관리 API")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class ClothesController {

    private final ClothesService clothesService;
    private final OutfitHistoryService outfitHistoryService;
    private final RembgService rembgService;
    private final GeminiApiClient geminiApiClient;
    private final UniqloProductSearchService uniqloProductSearchService;
    private final ProductCrawlerService productCrawlerService;
    private final S3ImageStorage s3ImageStorage;

    @Operation(
            summary = "옷 이미지 분석",
            description = "옷 이미지의 배경을 제거하고 옷 정보를 분석한다."
    )
    @PostMapping(
            value = "/analyze",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<ClothesAnalyzeResponse> analyzeClothesImage(
            @RequestPart("image") MultipartFile image
    ) {
        try {
            byte[] originalBytes = image.getBytes();
            byte[] processedBytes = rembgService.removeBackground(
                    originalBytes,
                    image.getOriginalFilename(),
                    image.getContentType()
            );

            String base64Image = Base64.getEncoder()
                    .encodeToString(processedBytes);

            ClothesAnalyzeResponse analyzedResponse =
                    geminiApiClient.analyzeClothingImage(
                            processedBytes,
                            base64Image
                    );

            String brand = analyzedResponse.getBrand();
            String name = analyzedResponse.getName();
            String material = analyzedResponse.getMaterial();
            int finalThickness = analyzedResponse.getThickness() != null
                    ? analyzedResponse.getThickness()
                    : 2;
            double finalCloValue = analyzedResponse.getCloValue() != null
                    ? analyzedResponse.getCloValue()
                    : 0.45;

            Optional<ProductSearchCandidate> matchedProduct =
                    uniqloProductSearchService.search(
                            analyzedResponse.getCategory(),
                            name
                    );

            String productUrl = matchedProduct
                    .map(ProductSearchCandidate::productUrl)
                    .orElse(null);

            if (productUrl != null && productUrl.startsWith("http")) {
                Map<String, String> crawledResult =
                        productCrawlerService.crawl(productUrl);

                if (crawledResult != null
                        && !crawledResult.getOrDefault("name", "").isEmpty()) {
                    String crawledBrand = crawledResult.get("brand");
                    String crawledName = crawledResult.get("name");
                    String crawledMaterial = crawledResult.get("material");

                    if (crawledBrand != null
                            && !crawledBrand.isBlank()) {
                        brand = crawledBrand;
                    }

                    if (crawledName != null
                            && !crawledName.isBlank()) {
                        name = crawledName;
                    }

                    if (crawledMaterial != null
                            && !crawledMaterial.isBlank()) {
                        material = crawledMaterial;

                        ClothesThermalAnalysis thermalAnalysis =
                                geminiApiClient.refineThermalValues(
                                        analyzedResponse.getCategory(),
                                        name,
                                        material,
                                        crawledResult.get("bodyText"),
                                        finalThickness,
                                        finalCloValue
                                );

                        if (thermalAnalysis != null) {
                            finalThickness =
                                    thermalAnalysis.thickness();
                            finalCloValue =
                                    thermalAnalysis.cloValue();
                        }
                    }
                }
            }

            int finalColorH = analyzedResponse.getColorH() != null
                    ? analyzedResponse.getColorH()
                    : 0;

            int finalColorS = analyzedResponse.getColorS() != null
                    ? analyzedResponse.getColorS()
                    : 0;

            int finalColorV = analyzedResponse.getColorV() != null
                    ? analyzedResponse.getColorV()
                    : 0;

            int[] localColor = extractDominantColor(processedBytes);

            if (localColor != null) {
                finalColorH = localColor[0];
                finalColorS = localColor[1];
                finalColorV = localColor[2];
            }

            String imageKey = s3ImageStorage.upload(
                    processedBytes,
                    "png",
                    "image/png"
            );
            String imageUrl = s3ImageStorage.getUrl(imageKey);

            ClothesAnalyzeResponse response =
                    ClothesAnalyzeResponse.builder()
                            .imageKey(imageKey)
                            .imageUrl(imageUrl)
                            .category(analyzedResponse.getCategory())
                            .style(analyzedResponse.getStyle())
                            .colorH(finalColorH)
                            .colorS(finalColorS)
                            .colorV(finalColorV)
                            .brand(brand)
                            .name(name)
                            .material(material)
                            .thickness(finalThickness)
                            .cloValue(finalCloValue)
                            .build();

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            throw new RuntimeException(
                    "옷 이미지 분석 중 오류가 발생했습니다.",
                    e
            );
        }
    }

    @Operation(
            summary = "옷 등록",
            description = "현재 사용자의 디지털 옷장에 새로운 옷을 등록한다."
    )
    @PostMapping
    public ResponseEntity<ClothesResponse> createClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @Valid @RequestBody ClothesCreateRequest request
    ) {
        ClothesResponse response = clothesService.createClothes(
                principal.getUserId(),
                request
        );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @Operation(
            summary = "옷 목록 조회",
            description = "현재 사용자의 옷을 카테고리와 스타일 조건으로 조회한다."
    )
    @GetMapping
    public ResponseEntity<SliceResponse<ClothesResponse>> getClothesList(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @RequestParam(required = false) Category category,
            @RequestParam(required = false) Style style,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(50) int size
    ) {
        SliceResponse<ClothesResponse> response =
                clothesService.getClothesList(
                        principal.getUserId(),
                        category,
                        style,
                        page,
                        size
                );

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "옷 상세 조회",
            description = "현재 사용자가 소유한 옷 한 개를 조회한다."
    )
    @GetMapping("/{id}")
    public ResponseEntity<ClothesResponse> getClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        ClothesResponse response = clothesService.getClothes(
                principal.getUserId(),
                id
        );

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "옷 착용 이력 조회",
            description = "현재 사용자가 소유한 옷의 착용 이력을 최신순으로 조회한다."
    )
    @GetMapping("/{id}/history")
    public ResponseEntity<SliceResponse<ClothesWearHistoryResponse>>
    getClothesWearHistory(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "10") @Min(1) @Max(50) int size
    ) {
        SliceResponse<ClothesWearHistoryResponse> response =
                outfitHistoryService.getClothesWearHistory(
                        principal.getUserId(),
                        id,
                        page,
                        size
                );

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "옷 수정",
            description = "현재 사용자가 소유한 옷의 정보를 선택적으로 수정한다."
    )
    @PatchMapping("/{id}")
    public ResponseEntity<ClothesResponse> updateClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody ClothesUpdateRequest request
    ) {
        ClothesResponse response = clothesService.updateClothes(
                principal.getUserId(),
                id,
                request
        );

        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "옷 삭제",
            description = "현재 사용자가 소유한 옷을 삭제한다."
    )
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteClothes(
            @AuthenticationPrincipal WearlyUserPrincipal principal,
            @PathVariable Long id
    ) {
        clothesService.deleteClothes(
                principal.getUserId(),
                id
        );

        return ResponseEntity.noContent().build();
    }

    private int[] extractDominantColor(byte[] imageBytes) {
        try {
            BufferedImage image = ImageIO.read(
                    new ByteArrayInputStream(imageBytes)
            );

            if (image == null) {
                return null;
            }

            long redSum = 0;
            long greenSum = 0;
            long blueSum = 0;
            int count = 0;

            for (int y = 0; y < image.getHeight(); y++) {
                for (int x = 0; x < image.getWidth(); x++) {
                    int argb = image.getRGB(x, y);
                    int alpha = (argb >> 24) & 0xff;

                    if (alpha <= 50) {
                        continue;
                    }

                    int red = (argb >> 16) & 0xff;
                    int green = (argb >> 8) & 0xff;
                    int blue = argb & 0xff;

                    if (red >= 240
                            && green >= 240
                            && blue >= 240) {
                        continue;
                    }

                    redSum += red;
                    greenSum += green;
                    blueSum += blue;
                    count++;
                }
            }

            if (count == 0) {
                return null;
            }

            int averageRed = (int) (redSum / count);
            int averageGreen = (int) (greenSum / count);
            int averageBlue = (int) (blueSum / count);

            float[] hsb = Color.RGBtoHSB(
                    averageRed,
                    averageGreen,
                    averageBlue,
                    null
            );

            return new int[]{
                    (int) (hsb[0] * 360),
                    (int) (hsb[1] * 100),
                    (int) (hsb[2] * 100)
            };
        } catch (Exception e) {
            return null;
        }
    }
}
