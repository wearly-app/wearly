package com.wearly.domain.clothes.service;

import com.wearly.domain.clothes.dto.response.ProductSearchCandidate;
import com.wearly.domain.clothes.entity.Category;
import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Service
public class MachoProductSearchService {

    private static final String BASE_URL = "https://macho707.com";
    private static final String USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    + "AppleWebKit/537.36 (KHTML, like Gecko) "
                    + "Chrome/120.0.0.0 Safari/537.36";

    private static final int CONNECTION_TIMEOUT_MILLIS = 5000;
    private static final int MAX_RESPONSE_BODY_SIZE = 2 * 1024 * 1024;
    private static final int MAX_PAGES = 10;
    private static final double MINIMUM_SIMILARITY = 0.45;
    private static final Duration CACHE_DURATION = Duration.ofMinutes(30);

    private final Map<Category, CachedProducts> cache =
            new EnumMap<>(Category.class);

    public Optional<ProductSearchCandidate> search(
            Category category,
            String analyzedName
    ) {
        if (analyzedName == null || analyzedName.isBlank()) {
            return Optional.empty();
        }

        String categoryUrl = getCategoryUrl(category);

        if (categoryUrl == null) {
            return Optional.empty();
        }

        Optional<ProductSearchCandidate> result = getProducts(
                category,
                categoryUrl
        ).stream()
                .map(product -> new ProductSearchCandidate(
                        product.name(),
                        product.productUrl(),
                        ProductNameSimilarity.calculate(
                                analyzedName,
                                product.name()
                        )
                ))
                .max(Comparator.comparingDouble(ProductSearchCandidate::similarity))
                .filter(product ->
                        product.similarity() >= MINIMUM_SIMILARITY
                );

        result.ifPresent(product -> log.info(
                "Macho product matched. analyzedName: {}, productName: {}, similarity: {}",
                analyzedName,
                product.name(),
                product.similarity()
        ));

        if (result.isEmpty()) {
            log.info(
                    "No sufficiently similar Macho product found. analyzedName: {}",
                    analyzedName
            );
        }

        return result;
    }

    private synchronized List<ProductSearchCandidate> getProducts(
            Category category,
            String categoryUrl
    ) {
        CachedProducts cachedProducts = cache.get(category);

        if (cachedProducts != null && !cachedProducts.isExpired()) {
            return cachedProducts.products();
        }

        List<ProductSearchCandidate> products = crawlCategory(
                categoryUrl
        );

        if (!products.isEmpty()) {
            cache.put(
                    category,
                    new CachedProducts(products, Instant.now())
            );
        }

        return products;
    }

    private List<ProductSearchCandidate> crawlCategory(
            String categoryUrl
    ) {
        Map<String, ProductSearchCandidate> productsByUrl =
                new LinkedHashMap<>();

        for (int page = 1; page <= MAX_PAGES; page++) {
            int previousSize = productsByUrl.size();

            try {
                Document document = Jsoup.connect(
                                categoryUrl + "?page=" + page
                        )
                        .userAgent(USER_AGENT)
                        .timeout(CONNECTION_TIMEOUT_MILLIS)
                        .maxBodySize(MAX_RESPONSE_BODY_SIZE)
                        .get();

                extractProducts(document, productsByUrl);
            } catch (Exception e) {
                log.error(
                        "Failed to crawl Macho category. url: {}, page: {}",
                        categoryUrl,
                        page,
                        e
                );

                break;
            }

            if (productsByUrl.size() == previousSize) {
                break;
            }
        }

        return new ArrayList<>(productsByUrl.values());
    }

    private void extractProducts(
            Document document,
            Map<String, ProductSearchCandidate> productsByUrl
    ) {
        for (Element element : document.select(
                "li[id^=anchorBoxId_] .description .name a, "
                        + "a[href*=/product/]"
        )) {
            String productUrl = element.absUrl("href");
            String productName = extractProductName(element);

            if (productUrl.isBlank() || productName.isBlank()) {
                continue;
            }

            productsByUrl.putIfAbsent(
                    productUrl,
                    new ProductSearchCandidate(
                            productName,
                            productUrl,
                            0.0
                    )
            );
        }
    }

    private String extractProductName(Element element) {
        String productName = element.text()
                .replace("\uC0C1\uD488\uBA85 :", "")
                .replace("\uC0C1\uD488\uBA85:", "")
                .trim();

        if (!productName.isBlank()) {
            return productName;
        }

        Element image = element.selectFirst("img[alt]");

        return image != null
                ? image.attr("alt").trim()
                : "";
    }

    private String getCategoryUrl(Category category) {
        return switch (category) {
            case TOP -> BASE_URL + "/category/%EC%83%81%EC%9D%98/42/";
            case BOTTOM -> BASE_URL + "/category/%ED%95%98%EC%9D%98/43/";
            case OUTER -> BASE_URL + "/category/%EC%95%84%EC%9A%B0%ED%84%B0/44/";
            case SHOES, BAG, ACCESSORY ->
                    BASE_URL + "/category/%EC%8B%A0%EB%B0%9C-acc/45/";
            case ONEPIECE -> null;
        };
    }

    private record CachedProducts(
            List<ProductSearchCandidate> products,
            Instant cachedAt
    ) {

        private boolean isExpired() {
            return cachedAt.plus(CACHE_DURATION)
                    .isBefore(Instant.now());
        }
    }
}
