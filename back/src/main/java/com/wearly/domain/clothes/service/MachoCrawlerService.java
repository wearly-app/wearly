package com.wearly.domain.clothes.service;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class MachoCrawlerService {

    private final GeminiApiClient geminiApiClient;

    public Map<String, String> crawlProductInfo(String url) {
        Map<String, String> result = new HashMap<>();
        try {
            // 1. 해당 URL의 HTML 문서 가져오기
            Document doc = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0")
                    .get();

            // 2. Open Graph 태그 추출
            String rawTitle = "";
            Element titleEl = doc.selectFirst("meta[property=og:title]");
            if (titleEl != null) rawTitle = titleEl.attr("content");

            String imageUrl = "";
            Element imageEl = doc.selectFirst("meta[property=og:image]");
            if (imageEl != null) {
                imageUrl = imageEl.attr("content");
                if (imageUrl.startsWith("//")) {
                    imageUrl = "https:" + imageUrl;
                }
            }

            // 3. 페이지 텍스트 긁어오기 (스크립트/스타일 제외)
            String bodyText = doc.body().text();

            // [중요] Cafe24 쇼핑몰 특성상 URL에 상품명이 포함된 경우가 많음
            String urlParsedName = "";
            try {
                String decodedUrl = java.net.URLDecoder.decode(url, "UTF-8");
                if (decodedUrl.contains("/product/")) {
                    String[] urlParts = decodedUrl.split("/product/")[1].split("/");
                    if (urlParts.length > 0 && !urlParts[0].isEmpty()) {
                        urlParsedName = urlParts[0].replace("-", " ").trim();
                    }
                }
            } catch (Exception ignore) {}

            // 4. Gemini AI에게 스마트 분석 맡기기 (URL에서 추출한 이름도 힌트로 제공)
            Map<String, String> aiExtracted = geminiApiClient.analyzeCrawledText(
                    urlParsedName.isEmpty() ? rawTitle : urlParsedName, bodyText);

            if (aiExtracted != null && !aiExtracted.getOrDefault("name", "정보 없음").equals("정보 없음")) {
                // AI가 이상하게 파싱할 수 있으므로, URL에서 확실하게 뽑은 이름이 있으면 우선순위 부여
                String aiName = aiExtracted.get("name");
                if (!urlParsedName.isEmpty() && aiName.contains("상남자들의 스타일")) {
                    aiName = urlParsedName;
                }
                
                result.put("name", aiName);
                result.put("brand", aiExtracted.getOrDefault("brand", "마초"));
                result.put("material", aiExtracted.getOrDefault("material", "정보 없음"));
                String fit = aiExtracted.getOrDefault("fit", "정보 없음");
                if (!fit.equals("정보 없음") && !result.get("name").contains(fit)) {
                    result.put("name", "[" + fit + "] " + result.get("name"));
                }
            } else {
                // [안전장치] AI 실패 시 자체 하드코딩 추출 (Cafe24 표준)
                String fallbackName = urlParsedName.isEmpty() ? rawTitle : urlParsedName;
                String fallbackBrand = "마초"; // URL이 macho707이므로 기본값
                
                // 타이틀에서 브랜드/상품명 분리 (URL 이름이 없을 경우만)
                if (urlParsedName.isEmpty()) {
                    if (rawTitle.contains("-")) {
                        String[] parts = rawTitle.split("-");
                        fallbackName = parts[parts.length - 1].trim();
                    } else if (rawTitle.contains("|")) {
                        String[] parts = rawTitle.split("\\|");
                        fallbackName = parts[parts.length - 1].trim();
                    }
                }

                // 2) 상세 정보 표(Table)에서 '소재' 직접 추출
                String fallbackMaterial = "정보 없음";
                Elements rows = doc.select("tbody tr");
                for (Element row : rows) {
                    String rowText = row.text();
                    if (rowText.contains("소재") || rowText.contains("혼용률") || rowText.contains("원단")) {
                        Element td = row.selectFirst("td");
                        if (td != null && !td.text().isEmpty()) {
                            fallbackMaterial = td.text().replace("소재", "").trim();
                        } else {
                            fallbackMaterial = rowText.replace("소재", "").replace("혼용률", "").trim();
                        }
                        break;
                    }
                }
                
                // 3) 상세 정보 표에서 '핏' 직접 추출
                String fallbackFit = "정보 없음";
                for (Element row : rows) {
                    if (row.text().contains("핏") || row.text().contains("신축성")) {
                        if (row.text().contains("머슬")) fallbackFit = "머슬핏";
                        else if (row.text().contains("오버")) fallbackFit = "오버핏";
                        else if (row.text().contains("레귤러")) fallbackFit = "레귤러핏";
                    }
                }

                if (!fallbackFit.equals("정보 없음") && !fallbackName.contains(fallbackFit)) {
                    fallbackName = "[" + fallbackFit + "] " + fallbackName;
                }

                result.put("name", fallbackName);
                result.put("brand", fallbackBrand);
                result.put("material", fallbackMaterial);
            }

            result.put("imageUrl", imageUrl);
            result.put("category", "TOP");

        } catch (Exception e) {
            System.err.println("크롤링 중 오류가 발생했습니다: " + e.getMessage());
        }
        return result;
    }
}
