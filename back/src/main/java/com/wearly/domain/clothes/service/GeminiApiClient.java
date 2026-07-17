package com.wearly.domain.clothes.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wearly.domain.clothes.dto.response.ClothesAnalyzeResponse;
import com.wearly.domain.clothes.entity.Category;
import com.wearly.global.common.entity.Style;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.*;

@Slf4j
@Component
public class GeminiApiClient {

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${gemini.api-key:}")
    private String apiKey;

    public GeminiApiClient(WebClient.Builder webClientBuilder, ObjectMapper objectMapper) {
        this.webClient = webClientBuilder.build();
        this.objectMapper = objectMapper;
    }

    public ClothesAnalyzeResponse analyzeClothingImage(byte[] imageBytes, String base64Image) {
        if (apiKey == null || apiKey.isEmpty()) {
            log.warn("Gemini API key is not configured. Falling back to default mock analysis.");
            return getMockAnalysis();
        }

        String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + apiKey;

        // Construct request payload
        Map<String, Object> requestBody = new HashMap<>();
        
        Map<String, Object> partText = new HashMap<>();
        partText.put("text", "Identify the clothing item in this image and extract details. " +
                "Respond strictly in JSON format matching this schema: " +
                "{ " +
                "\"category\": \"TOP\" or \"BOTTOM\" or \"OUTER\" or \"ONEPIECE\" or \"SHOES\" or \"BAG\" or \"ACCESSORY\", " +
                "\"style\": \"CASUAL\" or \"MINIMAL\" or \"STREET\" or \"SPORTY\" or \"FORMAL\" or \"VINTAGE\", " +
                "\"brand\": \"brand name (string, e.g. Uniqlo, divein) or null if not detected\", " +
                "\"material\": \"material text (string, e.g. Cotton 100%, Denim 100%)\", " +
                "\"thickness\": 1 (thin) or 2 (medium) or 3 (thick), " +
                "\"cloValue\": 0.15 (thin/summer) or 0.45 (light/spring) or 0.65 (medium/autumn) or 1.0 (warm/winter) or 1.6 (thick/heavy winter), " +
                "\"colorH\": dominant HSV color H value (integer, 0 to 360), " +
                "\"colorS\": dominant HSV color S value (integer, 0 to 100), " +
                "\"colorV\": dominant HSV color V value (integer, 0 to 100) " +
                "}. Do not add any markdown block wrappers (like ```json) or explanation, just plain JSON string.");

        Map<String, Object> partImage = new HashMap<>();
        Map<String, String> inlineData = new HashMap<>();
        inlineData.put("mimeType", "image/png");
        inlineData.put("data", base64Image);
        partImage.put("inlineData", inlineData);

        List<Map<String, Object>> parts = Arrays.asList(partText, partImage);
        
        Map<String, Object> content = new HashMap<>();
        content.put("parts", parts);
        
        requestBody.put("contents", Collections.singletonList(content));

        // Enforce JSON output format
        Map<String, String> generationConfig = new HashMap<>();
        generationConfig.put("responseMimeType", "application/json");
        requestBody.put("generationConfig", generationConfig);

        try {
            log.info("Sending request to Google Gemini API...");
            String rawResponse = webClient.post()
                    .uri(url)
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            log.info("Gemini raw response: {}", rawResponse);
            return parseGeminiResponse(rawResponse);
        } catch (Exception e) {
            log.error("Failed to analyze image with Gemini API, falling back to mock", e);
            return getMockAnalysis();
        }
    }

    private ClothesAnalyzeResponse parseGeminiResponse(String responseJson) {
        try {
            JsonNode root = objectMapper.readTree(responseJson);
            String text = root.path("candidates")
                    .path(0)
                    .path("content")
                    .path("parts")
                    .path(0)
                    .path("text")
                    .asText();

            log.info("Extracted text JSON from Gemini: {}", text);
            JsonNode data = objectMapper.readTree(text.trim());

            Category category = Category.valueOf(data.path("category").asText("TOP").toUpperCase());
            Style style = Style.valueOf(data.path("style").asText("CASUAL").toUpperCase());
            String brand = data.path("brand").isNull() ? null : data.path("brand").asText();
            String material = data.path("material").asText("코튼 100%");
            int thickness = data.path("thickness").asInt(2);
            double cloValue = data.path("cloValue").asDouble(0.65);
            int colorH = data.path("colorH").asInt(0);
            int colorS = data.path("colorS").asInt(0);
            int colorV = data.path("colorV").asInt(100);

            return ClothesAnalyzeResponse.builder()
                    .category(category)
                    .style(style)
                    .brand(brand)
                    .material(material)
                    .thickness(thickness)
                    .cloValue(cloValue)
                    .colorH(colorH)
                    .colorS(colorS)
                    .colorV(colorV)
                    .build();
        } catch (Exception e) {
            log.error("Error parsing Gemini JSON response, falling back to mock", e);
            return getMockAnalysis();
        }
    }

    private ClothesAnalyzeResponse getMockAnalysis() {
        log.info("Returning Mock clothes analysis response.");
        return ClothesAnalyzeResponse.builder()
                .category(Category.TOP)
                .style(Style.CASUAL)
                .colorH(0)
                .colorS(0)
                .colorV(90) // greyish white
                .brand("데모 브랜드")
                .material("코튼 100%")
                .thickness(2)
                .cloValue(0.65)
                .build();
    }
}
