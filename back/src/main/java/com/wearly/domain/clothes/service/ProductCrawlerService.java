package com.wearly.domain.clothes.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
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
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class ProductCrawlerService {

    private static final String USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    + "AppleWebKit/537.36 (KHTML, like Gecko) "
                    + "Chrome/120.0.0.0 Safari/537.36";

    private static final int CONNECTION_TIMEOUT_MILLIS = 7000;
    private static final int MAX_BODY_TEXT_LENGTH = 15000;
    private static final int MAX_RESPONSE_BODY_SIZE = 5 * 1024 * 1024;
    private static final String MACHO_HOST = "macho707.com";
    private static final String UNIQLO_HOST = "uniqlo.com";
    private static final Set<String> PRODUCT_TYPES = Set.of(
            "Product",
            "https://schema.org/Product"
    );

    private final ObjectMapper objectMapper;

    public Map<String, String> crawl(String targetUrl) {
        if (!isSupportedUrl(targetUrl)) {
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

            Map<String, String> result = createDefaultResult(
                    targetUrl
            );

            extractJsonLd(document, result);
            extractOpenGraph(document, result);
            extractProductNameFromUrl(targetUrl, result);
            extractProductDetails(document, result);
            extractUniqloMaterial(document, targetUrl, result);
            extractBodyText(document, result);

            log.info(
                    "Product detail crawled. url: {}, name: {}, brand: {}, material: {}",
                    targetUrl,
                    result.get("name"),
                    result.get("brand"),
                    result.get("material")
            );

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

    private boolean isSupportedUrl(String targetUrl) {
        try {
            URI uri = URI.create(targetUrl);
            String host = uri.getHost();
            String scheme = uri.getScheme();

            if (host == null || scheme == null) {
                return false;
            }

            boolean supportedScheme = scheme.equalsIgnoreCase("http")
                    || scheme.equalsIgnoreCase("https");

            return supportedScheme
                    && (isHost(host, MACHO_HOST)
                    || isHost(host, UNIQLO_HOST));
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private boolean isHost(String host, String supportedHost) {
        return host.equalsIgnoreCase(supportedHost)
                || host.toLowerCase().endsWith("." + supportedHost);
    }

    private Map<String, String> createDefaultResult(String targetUrl) {
        Map<String, String> result = new HashMap<>();
        String host = URI.create(targetUrl).getHost();

        result.put("name", "");
        result.put(
                "brand",
                isHost(host, UNIQLO_HOST)
                        ? "UNIQLO"
                        : "\uB9C8\uCD08"
        );
        result.put("material", "");
        result.put("fit", "");
        result.put("season", "");
        result.put("bodyText", "");

        return result;
    }

    private void extractJsonLd(
            Document document,
            Map<String, String> result
    ) {
        for (Element script : document.select(
                "script[type=application/ld+json]"
        )) {
            try {
                JsonNode root = objectMapper.readTree(script.data());
                JsonNode product = findProductNode(root);

                if (product == null) {
                    continue;
                }

                putIfPresent(result, "name", product.path("name"));
                putIfPresent(
                        result,
                        "material",
                        product.path("material")
                );

                JsonNode brand = product.path("brand");

                if (brand.isTextual()) {
                    putIfNotBlank(result, "brand", brand.asText());
                } else {
                    putIfPresent(result, "brand", brand.path("name"));
                }

                return;
            } catch (Exception e) {
                log.debug("Failed to parse product JSON-LD", e);
            }
        }
    }

    private JsonNode findProductNode(JsonNode node) {
        if (node == null || node.isMissingNode()) {
            return null;
        }

        if (node.isObject()) {
            JsonNode type = node.path("@type");

            if (type.isTextual()
                    && PRODUCT_TYPES.contains(type.asText())) {
                return node;
            }

            for (JsonNode child : node) {
                JsonNode product = findProductNode(child);

                if (product != null) {
                    return product;
                }
            }
        }

        if (node.isArray()) {
            for (JsonNode child : node) {
                JsonNode product = findProductNode(child);

                if (product != null) {
                    return product;
                }
            }
        }

        return null;
    }

    private void extractOpenGraph(
            Document document,
            Map<String, String> result
    ) {
        if (result.get("name").isBlank()) {
            Element titleMeta = document.selectFirst(
                    "meta[property=og:title]"
            );

            if (titleMeta != null) {
                putIfNotBlank(
                        result,
                        "name",
                        titleMeta.attr("content")
                );
            }
        }

        Element imageMeta = document.selectFirst(
                "meta[property=og:image]"
        );

        if (imageMeta != null) {
            putIfNotBlank(
                    result,
                    "productImageUrl",
                    imageMeta.attr("content")
            );
        }
    }

    private void extractProductNameFromUrl(
            String targetUrl,
            Map<String, String> result
    ) {
        if (!result.get("name").isBlank()
                || !targetUrl.contains("macho707.com/product/")) {
            return;
        }

        try {
            String decodedUrl = URLDecoder.decode(
                    targetUrl,
                    StandardCharsets.UTF_8
            );
            String productName = decodedUrl
                    .split("/product/", 2)[1]
                    .split("/", 2)[0]
                    .replace("-", " ")
                    .trim();

            putIfNotBlank(result, "name", productName);
        } catch (Exception e) {
            log.debug(
                    "Failed to extract product name from URL: {}",
                    targetUrl,
                    e
            );
        }
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

            if (header.contains("\uC18C\uC7AC")
                    || header.contains("\uD63C\uC6A9\uB960")) {
                putIfNotBlank(result, "material", value);
            } else if (header.contains("\uD54F")) {
                putIfNotBlank(result, "fit", value);
            } else if (header.contains("\uACC4\uC808")) {
                putIfNotBlank(result, "season", value);
            }
        }
    }

    private void extractUniqloMaterial(
            Document document,
            String targetUrl,
            Map<String, String> result
    ) {
        if (!targetUrl.contains("uniqlo.com")
                || !result.get("material").isBlank()) {
            return;
        }

        String bodyText = document.text();
        String sectionLabel =
                "\uC18C\uC7AC \uC815\uBCF4 / \uC138\uD0C1 \uBC29\uBC95";
        String materialLabel = "\uC18C\uC7AC";
        String washingLabel = "\uC138\uD0C1 \uBC29\uBC95";

        int sectionStart = bodyText.indexOf(sectionLabel);

        if (sectionStart < 0) {
            return;
        }

        int materialStart = bodyText.indexOf(
                materialLabel,
                sectionStart + sectionLabel.length()
        );

        if (materialStart < 0) {
            return;
        }

        materialStart += materialLabel.length();

        int materialEnd = bodyText.indexOf(
                washingLabel,
                materialStart
        );

        if (materialEnd < 0) {
            return;
        }

        String material = bodyText.substring(
                materialStart,
                materialEnd
        ).trim();

        putIfNotBlank(result, "material", material);
    }

    private void extractBodyText(
            Document document,
            Map<String, String> result
    ) {
        String bodyText = document.text();

        if (bodyText.length() > MAX_BODY_TEXT_LENGTH) {
            bodyText = bodyText.substring(0, MAX_BODY_TEXT_LENGTH);
        }

        result.put("bodyText", bodyText);
    }

    private void putIfPresent(
            Map<String, String> result,
            String key,
            JsonNode value
    ) {
        if (value.isTextual()) {
            putIfNotBlank(result, key, value.asText());
        }
    }

    private void putIfNotBlank(
            Map<String, String> result,
            String key,
            String value
    ) {
        if (value != null && !value.isBlank()) {
            result.put(key, value.trim());
        }
    }
}
