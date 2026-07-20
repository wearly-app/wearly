package com.wearly.domain.clothes.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wearly.domain.clothes.dto.response.ClothesAnalyzeResponse;
import com.wearly.domain.clothes.dto.response.ClothesThermalAnalysis;
import com.wearly.domain.clothes.entity.Category;
import com.wearly.global.common.entity.Style;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.nio.charset.StandardCharsets;
import java.util.*;

@Slf4j
@Component
public class GeminiApiClient {

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${gemini.api-key:}")
    private String apiKey;

    @Value("${gemini.model:gemini-3.5-flash}")
    private String model;

    public GeminiApiClient(WebClient.Builder webClientBuilder, ObjectMapper objectMapper) {
        this.webClient = webClientBuilder.build();
        this.objectMapper = objectMapper;
    }

    public ClothesAnalyzeResponse analyzeClothingImage(byte[] imageBytes, String base64Image) {
        if (apiKey == null || apiKey.isEmpty()) {
            log.warn("Gemini API key is not configured. Falling back to default mock analysis.");
            return getMockAnalysis();
        }

        String url = createGenerateContentUrl();

        // Construct request payload
        Map<String, Object> requestBody = new HashMap<>();
        
        Map<String, Object> partText = new HashMap<>();
        partText.put("text", "Identify the clothing item in this image and extract details. " +
                "The name field must be a short generic clothing name written in Korean Hangul. " +
                "Assume this item will be searched on UNIQLO Korea, so the name field should use Korean product-search terms commonly used by UNIQLO. " +
                "For example, use terms like 반팔 티셔츠, 크루넥 티셔츠, 피케 폴로셔츠, 카라 티셔츠, 와이드 치노 팬츠, or 슬림 치노 팬츠 when they match visible features. " +
                "Do not guess exact technology, collaboration, or line names such as AIRism, DRY, JW Anderson, or U unless the logo, label, or printed text clearly supports it. " +
                "Respond strictly in JSON format matching this schema: " +
                "{ " +
                "\"category\": \"TOP\" or \"BOTTOM\" or \"OUTER\" or \"ONEPIECE\" or \"SHOES\" or \"BAG\" or \"ACCESSORY\", " +
                "\"style\": \"CASUAL\" or \"MINIMAL\" or \"STREET\" or \"SPORTY\" or \"FORMAL\" or \"VINTAGE\", " +
                "\"name\": \"a short generic Korean clothing name based only on visible features, e.g. 카고 와이드 팬츠\", " +
                "\"searchKeywords\": [\"three to four short Korean UNIQLO search queries based on visible features, e.g. 반팔 티셔츠, 크루넥 티셔츠, 크루넥T\"], " +
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
        Map<String, Object> generationConfig = new HashMap<>();
        generationConfig.put("responseMimeType", "application/json");
        generationConfig.put("maxOutputTokens", 2048);
        requestBody.put("generationConfig", generationConfig);

        try {
            log.info("Sending request to Google Gemini API...");
            String rawResponse = executeRequest(url, requestBody);

            log.info("Gemini raw response: {}", rawResponse);

            try {
                return parseGeminiResponseOrThrow(rawResponse);
            } catch (Exception firstParseException) {
                log.warn(
                        "Gemini response parsing failed. Retrying once.",
                        firstParseException
                );

                String retryResponse = executeRequest(url, requestBody);
                log.info("Gemini retry raw response: {}", retryResponse);

                return parseGeminiResponseOrThrow(retryResponse);
            }
        } catch (Exception e) {
            log.error("Failed to analyze image with Gemini API, falling back to mock", e);
            return getMockAnalysis();
        }
    }

    private ClothesAnalyzeResponse parseGeminiResponseOrThrow(
            String responseJson
    ) throws Exception {
        JsonNode root = objectMapper.readTree(responseJson);
        String text = root.path("candidates")
                .path(0)
                .path("content")
                .path("parts")
                .path(0)
                .path("text")
                .asText();

        log.info("Extracted text JSON from Gemini: {}", text);
        JsonNode data = objectMapper.readTree(cleanJsonText(text));

        Category category = Category.valueOf(
                data.path("category").asText("TOP").toUpperCase()
        );
        Style style = Style.valueOf(
                data.path("style").asText("CASUAL").toUpperCase()
        );
        String name = data.path("name").asText("");
        String brand = data.path("brand").isNull()
                ? null
                : data.path("brand").asText();
        String material = data.path("material")
                .asText("Cotton 100%");
        List<String> searchKeywords = new ArrayList<>();

        if (data.path("searchKeywords").isArray()) {
            data.path("searchKeywords").forEach(keyword -> {
                String value = keyword.asText("").trim();

                if (!value.isBlank()) {
                    searchKeywords.add(value);
                }
            });
        }

        int thickness = data.path("thickness").asInt(2);
        double cloValue = data.path("cloValue").asDouble(0.65);
        int colorH = data.path("colorH").asInt(0);
        int colorS = data.path("colorS").asInt(0);
        int colorV = data.path("colorV").asInt(100);

        return ClothesAnalyzeResponse.builder()
                .category(category)
                .style(style)
                .name(name)
                .brand(brand)
                .material(material)
                .searchKeywords(searchKeywords)
                .thickness(thickness)
                .cloValue(cloValue)
                .colorH(colorH)
                .colorS(colorS)
                .colorV(colorV)
                .build();
    }

    private String cleanJsonText(String text) {
        String cleanText = text == null ? "" : text.trim();

        if (cleanText.startsWith("```json")) {
            cleanText = cleanText.substring(7);
        } else if (cleanText.startsWith("```")) {
            cleanText = cleanText.substring(3);
        }

        if (cleanText.endsWith("```")) {
            cleanText = cleanText.substring(
                    0,
                    cleanText.length() - 3
            );
        }

        cleanText = cleanText.trim();

        if (cleanText.startsWith("{")
                && !cleanText.endsWith("}")) {
            cleanText = cleanText + "}";
            log.warn("Completed a missing closing brace in Gemini JSON.");
        }

        return cleanText;
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
            String cleanText = text.trim();
            if (cleanText.startsWith("```json")) {
                cleanText = cleanText.substring(7);
            } else if (cleanText.startsWith("```")) {
                cleanText = cleanText.substring(3);
            }
            if (cleanText.endsWith("```")) {
                cleanText = cleanText.substring(0, cleanText.length() - 3);
            }
            JsonNode data = objectMapper.readTree(cleanText.trim());

            Category category = Category.valueOf(data.path("category").asText("TOP").toUpperCase());
            Style style = Style.valueOf(data.path("style").asText("CASUAL").toUpperCase());
            String name = data.path("name").asText("");
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
                    .name(name)
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
    public String findProductUrl(String base64Image, String storeHint) {
        if (apiKey == null || apiKey.isEmpty()) {
            return "https://macho707.com/product/%EC%BA%90%EC%8B%9C%EB%AF%B8%EC%96%B4-%EC%9A%B8-%EB%A8%B8%EC%8A%AC%ED%95%8F-%ED%97%A8%EB%A6%AC%EB%84%A5-%EB%8B%88%ED%8A%B8/204/";
        }
        String url = createGenerateContentUrl();
        Map<String, Object> requestBody = new HashMap<>();
        Map<String, Object> partText = new HashMap<>();
        partText.put("text", "Find the exact product webpage URL for this clothing item " +
                "only on the macho707.com online store. " +
                "Do not return a URL from any other domain. " +
                "Respond ONLY with a macho707.com product URL " +
                "(e.g. https://macho707.com/product/...). " +
                "Do not add any other text.");
        Map<String, Object> partImage = new HashMap<>();
        Map<String, String> inlineData = new HashMap<>();
        inlineData.put("mimeType", "image/png");
        inlineData.put("data", base64Image);
        partImage.put("inlineData", inlineData);
        requestBody.put("contents", Collections.singletonList(Collections.singletonMap("parts", Arrays.asList(partText, partImage))));

        try {
            log.info("Sending request to Gemini API to find URL...");
            String rawResponse = executeRequest(url, requestBody);
            JsonNode root = objectMapper.readTree(rawResponse);
            String foundUrl = root.path("candidates").path(0).path("content").path("parts").path(0).path("text").asText().trim();
            int httpIndex = foundUrl.indexOf("http");
            if (httpIndex != -1) {
                foundUrl = foundUrl.substring(httpIndex);
                int spaceIndex = foundUrl.indexOf(" ");
                int newlineIndex = foundUrl.indexOf("\n");
                int endIndex = foundUrl.length();
                if (spaceIndex != -1 && spaceIndex < endIndex) endIndex = spaceIndex;
                if (newlineIndex != -1 && newlineIndex < endIndex) endIndex = newlineIndex;
                
                return foundUrl.substring(0, endIndex).trim();
            }
        } catch (Exception e) {
            log.error("Error finding URL via Gemini", e);
        }
        return "https://macho707.com/product/%EC%BA%90%EC%8B%9C%EB%AF%B8%EC%96%B4-%EC%9A%B8-%EB%A8%B8%EC%8A%AC%ED%95%8F-%ED%97%A8%EB%A6%AC%EB%84%A5-%EB%8B%88%ED%8A%B8/204/"; // Fallback
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

    public ClothesThermalAnalysis refineThermalValues(
            Category category,
            String name,
            String material,
            String description,
            Integer currentThickness,
            Double currentCloValue
    ) {
        if (apiKey == null
                || apiKey.isBlank()
                || material == null
                || material.isBlank()) {
            return null;
        }

        String safeDescription = description == null
                ? ""
                : description;

        if (safeDescription.length() > 3000) {
            safeDescription = safeDescription.substring(0, 3000);
        }

        String prompt = "Estimate clothing thickness and thermal insulation "
                + "using the product information below. "
                + "Use the current image analysis values as a reference, "
                + "but correct them when the material or description provides "
                + "better evidence. Respond only as JSON. "
                + "thickness must be 1 (thin), 2 (medium), or 3 (thick). "
                + "cloValue must be between 0.05 and 2.0.\n"
                + "category: " + category + "\n"
                + "name: " + name + "\n"
                + "material: " + material + "\n"
                + "description: " + safeDescription + "\n"
                + "currentThickness: " + currentThickness + "\n"
                + "currentCloValue: " + currentCloValue + "\n"
                + "Required JSON schema: "
                + "{\"thickness\": 1, \"cloValue\": 0.15}";

        Map<String, Object> textPart = new HashMap<>();
        textPart.put("text", prompt);

        Map<String, Object> content = new HashMap<>();
        content.put("parts", Collections.singletonList(textPart));

        Map<String, Object> generationConfig = new HashMap<>();
        generationConfig.put("responseMimeType", "application/json");
        generationConfig.put("maxOutputTokens", 1024);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put(
                "contents",
                Collections.singletonList(content)
        );
        requestBody.put("generationConfig", generationConfig);

        try {
            log.info(
                    "Sending thermal refinement request to Gemini. name: {}, material: {}",
                    name,
                    material
            );

            String rawResponse = executeRequest(
                    createGenerateContentUrl(),
                    requestBody
            );
            JsonNode root = objectMapper.readTree(rawResponse);
            String text = root.path("candidates")
                    .path(0)
                    .path("content")
                    .path("parts")
                    .path(0)
                    .path("text")
                    .asText();
            JsonNode data = objectMapper.readTree(cleanJsonText(text));

            int thickness = data.path("thickness")
                    .asInt(currentThickness != null ? currentThickness : 2);
            double cloValue = data.path("cloValue")
                    .asDouble(currentCloValue != null ? currentCloValue : 0.45);

            if (thickness < 1
                    || thickness > 3
                    || cloValue < 0.05
                    || cloValue > 2.0) {
                log.warn(
                        "Invalid thermal refinement response. thickness: {}, cloValue: {}",
                        thickness,
                        cloValue
                );

                return null;
            }

            log.info(
                    "Thermal values refined. thickness: {} -> {}, cloValue: {} -> {}",
                    currentThickness,
                    thickness,
                    currentCloValue,
                    cloValue
            );

            return new ClothesThermalAnalysis(
                    thickness,
                    cloValue
            );
        } catch (Exception e) {
            log.error(
                    "Failed to refine thermal values with Gemini. Keeping image analysis values.",
                    e
            );

            return null;
        }
    }

    public Map<String, String> analyzeCrawledText(String title, String bodyText) {
        if (apiKey == null || apiKey.isEmpty()) {
            return null;
        }

        String url = createGenerateContentUrl();

        if (bodyText != null && bodyText.length() > 6000) {
            bodyText = bodyText.substring(0, 6000); // Limit tokens
        }

        Map<String, Object> requestBody = new HashMap<>();
        Map<String, Object> partText = new HashMap<>();
        partText.put("text", "Extract clothing product details from the following webpage title and text.\n" +
                "Title: " + title + "\n" +
                "Text: " + bodyText + "\n\n" +
                "Respond strictly in JSON format matching this schema:\n" +
                "{ \"brand\": \"Brand name extracted from title or text (e.g. 마초, MACHO)\", " +
                "\"name\": \"Clean product name without brand (e.g. 캐시미어 울 머슬핏 헨리넥 니트)\", " +
                "\"material\": \"Material or fabric information (e.g. 울 50% 아크릴 50%, 코튼 100%)\", " +
                "\"fit\": \"Fit information (e.g. 머슬핏, 오버핏, 레귤러핏)\" }.\n" +
                "If not found, use '정보 없음'. Do not add any markdown block wrappers, just plain JSON.");

        requestBody.put("contents", Collections.singletonList(Collections.singletonMap("parts", Collections.singletonList(partText))));

        Map<String, String> generationConfig = new HashMap<>();
        generationConfig.put("responseMimeType", "application/json");
        requestBody.put("generationConfig", generationConfig);

        try {
            log.info("Sending text analysis request to Gemini...");
            String rawResponse = executeRequest(url, requestBody);

            JsonNode root = objectMapper.readTree(rawResponse);
            String text = root.path("candidates").path(0).path("content").path("parts").path(0).path("text").asText();
            
            // Clean markdown code blocks if Gemini ignores instructions
            String cleanText = text.trim();
            if (cleanText.startsWith("```json")) {
                cleanText = cleanText.substring(7);
            } else if (cleanText.startsWith("```")) {
                cleanText = cleanText.substring(3);
            }
            if (cleanText.endsWith("```")) {
                cleanText = cleanText.substring(0, cleanText.length() - 3);
            }
            cleanText = cleanText.trim();

            JsonNode data = objectMapper.readTree(cleanText);

            Map<String, String> result = new HashMap<>();
            result.put("brand", data.path("brand").asText("정보 없음"));
            result.put("name", data.path("name").asText("정보 없음"));
            result.put("material", data.path("material").asText("정보 없음"));
            result.put("fit", data.path("fit").asText("정보 없음"));
            return result;
        } catch (Exception e) {
            log.error("Failed to analyze crawled text with Gemini", e);
            return null;
        }
    }

    private String executeRequest(
            String url,
            Map<String, Object> requestBody
    ) {
        byte[] responseBytes = webClient.post()
                .uri(url)
                .header(
                        HttpHeaders.CONTENT_TYPE,
                        MediaType.APPLICATION_JSON_VALUE
                )
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(byte[].class)
                .block();

        if (responseBytes == null || responseBytes.length == 0) {
            throw new IllegalStateException(
                    "Gemini API returned an empty response."
            );
        }

        return new String(
                responseBytes,
                StandardCharsets.UTF_8
        );
    }

    private String createGenerateContentUrl() {
        return "https://generativelanguage.googleapis.com/v1beta/models/"
                + model.trim()
                + ":generateContent?key="
                + apiKey.trim();
    }
}
