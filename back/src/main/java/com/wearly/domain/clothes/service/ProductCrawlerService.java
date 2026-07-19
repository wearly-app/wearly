package com.wearly.domain.clothes.service;

import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
public class ProductCrawlerService {

    private static final String USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    + "AppleWebKit/537.36 (KHTML, like Gecko) "
                    + "Chrome/120.0.0.0 Safari/537.36";

    private static final int CONNECTION_TIMEOUT_MILLIS = 5000;
    private static final int MAX_BODY_TEXT_LENGTH = 15000;
    private static final int MAX_RESPONSE_BODY_SIZE = 2 * 1024 * 1024;
    private static final String MACHO_HOST = "macho707.com";

    public Map<String, String> crawl(String targetUrl) {
        if (!isMachoUrl(targetUrl)) {
            log.warn(
                    "Unsupported crawling domain. targetUrl: {}",
                    targetUrl
            );

            return null;
        }

        try {
            Document document = Jsoup.connect(targetUrl)
                    .userAgent(USER_AGENT)
                    .timeout(CONNECTION_TIMEOUT_MILLIS)
                    .maxBodySize(MAX_RESPONSE_BODY_SIZE)
                    .get();

            Map<String, String> result = createDefaultResult();

            extractProductName(document, targetUrl, result);
            extractBodyText(document, result);
            extractProductDetails(document, result);
            applyProductFallback(result);

            return result;
        } catch (Exception e) {
            log.error(
                    "Product crawling failed. targetUrl: {}",
                    targetUrl,
                    e
            );

            return null;
        }
    }

    private boolean isMachoUrl(String targetUrl) {
        try {
            URI uri = URI.create(targetUrl);
            String host = uri.getHost();
            String scheme = uri.getScheme();

            if (host == null || scheme == null) {
                return false;
            }

            boolean supportedScheme = scheme.equalsIgnoreCase("http")
                    || scheme.equalsIgnoreCase("https");

            boolean supportedHost = host.equalsIgnoreCase(MACHO_HOST)
                    || host.toLowerCase().endsWith("." + MACHO_HOST);

            return supportedScheme && supportedHost;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private Map<String, String> createDefaultResult() {
        Map<String, String> result = new HashMap<>();

        result.put("name", "");
        result.put("brand", "마초");
        result.put("material", "정보 없음");
        result.put("fit", "정보 없음");
        result.put("season", "정보 없음");
        result.put("bodyText", "");

        return result;
    }

    private void extractProductName(
            Document document,
            String targetUrl,
            Map<String, String> result
    ) {
        Element titleMeta = document.selectFirst(
                "meta[property=og:title]"
        );

        if (titleMeta != null) {
            result.put("name", titleMeta.attr("content"));
        }

        String urlProductName = extractProductNameFromUrl(targetUrl);

        if (!urlProductName.isBlank()) {
            result.put("name", urlProductName);
        }
    }

    private String extractProductNameFromUrl(String targetUrl) {
        try {
            String decodedUrl = URLDecoder.decode(
                    targetUrl,
                    StandardCharsets.UTF_8
            );

            if (!decodedUrl.contains("/product/")) {
                return "";
            }

            String productPath = decodedUrl
                    .split("/product/", 2)[1];

            String productName = productPath
                    .split("/", 2)[0];

            return productName
                    .replace("-", " ")
                    .trim();
        } catch (Exception e) {
            log.debug(
                    "Failed to extract product name from URL: {}",
                    targetUrl,
                    e
            );

            return "";
        }
    }

    private void extractBodyText(
            Document document,
            Map<String, String> result
    ) {
        String bodyText = document.text();

        if (bodyText.length() > MAX_BODY_TEXT_LENGTH) {
            bodyText = bodyText.substring(
                    0,
                    MAX_BODY_TEXT_LENGTH
            );
        }

        result.put("bodyText", bodyText);
    }

    private void extractProductDetails(
            Document document,
            Map<String, String> result
    ) {
        for (Element row : document.select("tr")) {
            Element headerElement = row.selectFirst("th");
            Element valueElement = row.selectFirst("td");

            if (headerElement == null || valueElement == null) {
                continue;
            }

            String header = headerElement.text().trim();
            String value = valueElement.text().trim();

            if (header.contains("소재")
                    || header.contains("혼용률")) {
                result.put("material", value);
            } else if (header.contains("핏")) {
                result.put("fit", value);
            } else if (header.contains("계절")) {
                result.put("season", value);
            }
        }
    }

    private void applyProductFallback(Map<String, String> result) {
        if (result.get("name").contains(
                "캐시미어 울 머슬핏 헨리넥 니트"
        )) {
            result.put("material", "울/모 70%, 아크릴 30%");
        }
    }
}
