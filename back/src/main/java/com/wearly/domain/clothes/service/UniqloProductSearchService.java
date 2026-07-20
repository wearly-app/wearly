package com.wearly.domain.clothes.service;

import com.wearly.domain.clothes.dto.response.ProductSearchCandidate;
import com.wearly.domain.clothes.entity.Category;
import lombok.extern.slf4j.Slf4j;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Service
public class UniqloProductSearchService {

    private static final String SEARCH_URL =
            "https://www.uniqlo.com/kr/ko/search?q=";
    private static final String USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    + "AppleWebKit/537.36 (KHTML, like Gecko) "
                    + "Chrome/120.0.0.0 Safari/537.36";

    private static final int CONNECTION_TIMEOUT_MILLIS = 7000;
    private static final int MAX_RESPONSE_BODY_SIZE = 5 * 1024 * 1024;
    private static final double MINIMUM_SIMILARITY = 0.45;
    private static final Duration CACHE_DURATION = Duration.ofMinutes(30);

    private final Map<String, CachedProducts> cache = new HashMap<>();

    public Optional<ProductSearchCandidate> search(
            Category category,
            String analyzedName
    ) {
        return search(category, analyzedName, List.of());
    }

    public Optional<ProductSearchCandidate> search(
            Category category,
            String analyzedName,
            List<String> analyzedSearchKeywords
    ) {
        if (category == null
                || analyzedName == null
                || analyzedName.isBlank()) {
            return Optional.empty();
        }

        List<String> searchKeywords = createSearchKeywords(
                analyzedName,
                analyzedSearchKeywords
        );
        Map<String, ProductSearchCandidate> productsByUrl =
                new LinkedHashMap<>();

        for (String searchKeyword : searchKeywords) {
            for (ProductSearchCandidate product : getProducts(
                    searchKeyword
            )) {
                productsByUrl.putIfAbsent(
                        product.productUrl(),
                        product
                );
            }
        }

        List<ProductSearchCandidate> products =
                new ArrayList<>(productsByUrl.values());
        List<String> comparisonNames = new ArrayList<>();
        comparisonNames.add(analyzedName);
        comparisonNames.addAll(searchKeywords);

        Optional<ProductSearchCandidate> bestCandidate = products.stream()
                .map(product -> new ProductSearchCandidate(
                        product.name(),
                        product.productUrl(),
                        comparisonNames.stream()
                                .mapToDouble(name ->
                                        ProductNameSimilarity.calculate(
                                                name,
                                                product.name()
                                        )
                                )
                                .max()
                                .orElse(0.0)
                ))
                .max(Comparator.comparingDouble(
                        ProductSearchCandidate::similarity
                ));

        bestCandidate.ifPresent(product -> log.info(
                "Uniqlo best candidate. analyzedName: {}, searchKeywords: {}, productName: {}, similarity: {}, url: {}",
                analyzedName,
                searchKeywords,
                product.name(),
                product.similarity(),
                product.productUrl()
        ));

        Optional<ProductSearchCandidate> result = bestCandidate
                .filter(product ->
                        product.similarity() >= MINIMUM_SIMILARITY
                );

        result.ifPresent(product -> log.info(
                "Uniqlo product matched. analyzedName: {}, productName: {}, similarity: {}",
                analyzedName,
                product.name(),
                product.similarity()
        ));

        if (bestCandidate.isEmpty()) {
            log.info(
                    "No Uniqlo product candidate found. keyword: {}",
                    analyzedName
            );
        } else if (result.isEmpty()) {
            log.info(
                    "Uniqlo best candidate did not meet similarity threshold. analyzedName: {}, searchKeywords: {}, similarity: {}, threshold: {}, candidateCount: {}",
                    analyzedName,
                    searchKeywords,
                    bestCandidate.get().similarity(),
                    MINIMUM_SIMILARITY,
                    products.size()
            );
        }

        return result;
    }

    List<String> createSearchKeywords(
            String analyzedName,
            List<String> analyzedSearchKeywords
    ) {
        LinkedHashSet<String> keywords = new LinkedHashSet<>();

        addKeyword(keywords, analyzedName);

        String normalizedName = analyzedName.replace("반소매", "반팔");
        addKeyword(keywords, normalizedName);

        if (analyzedSearchKeywords != null) {
            analyzedSearchKeywords.forEach(keyword ->
                    addKeyword(keywords, keyword)
            );
        }

        boolean hasCollar = normalizedName.contains("카라")
                || normalizedName.contains("폴로");
        boolean isShortSleeve = normalizedName.contains("반팔")
                || normalizedName.contains("숏슬리브");
        boolean isTShirt = normalizedName.contains("티셔츠")
                || normalizedName.endsWith("T")
                || normalizedName.endsWith("티");

        if (isTShirt && isShortSleeve) {
            addKeyword(keywords, "반팔 티셔츠");
        }

        if (isTShirt && !hasCollar) {
            addKeyword(keywords, "크루넥 티셔츠");
            addKeyword(keywords, "크루넥T");
        }

        if (hasCollar) {
            if (isShortSleeve) {
                addKeyword(keywords, "반팔 폴로셔츠");
            }

            if (normalizedName.contains("니트")) {
                addKeyword(keywords, "니트 폴로셔츠");
            }

            addKeyword(keywords, "피케 폴로셔츠");
            addKeyword(keywords, "카라 티셔츠");
            addKeyword(keywords, "폴로셔츠");
        }

        return keywords.stream()
                .limit(6)
                .toList();
    }

    private void addKeyword(
            LinkedHashSet<String> keywords,
            String keyword
    ) {
        if (keyword == null || keyword.isBlank()) {
            return;
        }

        keywords.add(keyword.trim());
    }

    private synchronized List<ProductSearchCandidate> getProducts(
            String searchKeyword
    ) {
        String cacheKey = searchKeyword.toLowerCase();
        CachedProducts cachedProducts = cache.get(cacheKey);

        if (cachedProducts != null && !cachedProducts.isExpired()) {
            return cachedProducts.products();
        }

        List<ProductSearchCandidate> products = searchProducts(
                searchKeyword
        );

        if (!products.isEmpty()) {
            cache.put(
                    cacheKey,
                    new CachedProducts(products, Instant.now())
            );
        }

        return products;
    }

    private List<ProductSearchCandidate> searchProducts(
            String searchKeyword
    ) {
        Map<String, ProductSearchCandidate> productsByUrl =
                new LinkedHashMap<>();
        String encodedKeyword = URLEncoder.encode(
                searchKeyword,
                StandardCharsets.UTF_8
        );
        String searchUrl = SEARCH_URL + encodedKeyword;

        try {
            Document document = Jsoup.connect(searchUrl)
                    .userAgent(USER_AGENT)
                    .timeout(CONNECTION_TIMEOUT_MILLIS)
                    .maxBodySize(MAX_RESPONSE_BODY_SIZE)
                    .get();

            for (Element link : document.select(
                    "a[href*=/kr/ko/products/E]"
            )) {
                String productUrl = link.absUrl("href");
                String productName = extractProductName(link);

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
        } catch (Exception e) {
            log.error(
                    "Failed to crawl Uniqlo search result. keyword: {}, url: {}",
                    searchKeyword,
                    searchUrl,
                    e
            );
        }

        log.info(
                "Uniqlo search result crawled. keyword: {}, productCount: {}",
                searchKeyword,
                productsByUrl.size()
        );

        return new ArrayList<>(productsByUrl.values());
    }

    private String extractProductName(Element link) {
        String ariaLabel = link.attr("aria-label").trim();

        if (!ariaLabel.isBlank()) {
            return ariaLabel;
        }

        Element image = link.selectFirst("img[alt]");

        if (image != null && !image.attr("alt").isBlank()) {
            return image.attr("alt").trim();
        }

        String linkText = link.text().trim();

        if (!linkText.isBlank()) {
            return linkText;
        }

        Element productCard = link.closest(
                "article, li, [class*=product]"
        );

        return productCard != null
                ? productCard.text().trim()
                : "";
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
