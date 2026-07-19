package com.wearly.domain.clothes.service;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

final class ProductNameSimilarity {

    private static final List<String> CLOTHING_KEYWORDS = List.of(
            // 하의 종류
            "치노",
            "와이드",
            "슬림",
            "스키니",
            "스트레이트",
            "테이퍼드",
            "부츠컷",
            "플레어",
            "배기",
            "카고",
            "조거",
            "밴딩",
            "데님",
            "청바지",
            "팬츠",
            "슬랙스",
            "반바지",
            "쇼츠",
            "버뮤다",
            "큐롯",
            "레깅스",
            "트레이닝팬츠",
            "스웨트팬츠",

            // 상의 종류
            "셔츠",
            "블라우스",
            "티셔츠",
            "티",
            "니트",
            "스웨터",
            "가디건",
            "후드",
            "후드티",
            "맨투맨",
            "스웨트셔츠",
            "폴로",
            "카라티",
            "탑",
            "나시",
            "터틀넥",
            "목폴라",

            // 아우터
            "자켓",
            "재킷",
            "점퍼",
            "코트",
            "패딩",
            "바람막이",
            "윈드브레이커",
            "블레이저",
            "트렌치",
            "트렌치코트",
            "야상",
            "항공점퍼",
            "봄버",
            "무스탕",
            "베스트",
            "조끼",
            "집업",
            "후드집업",

            // 원피스·스커트
            "원피스",
            "드레스",
            "스커트",
            "미니스커트",
            "롱스커트",
            "플리츠",
            "랩스커트",
            "점프수트",
            "오버롤",

            // 핏
            "오버핏",
            "루즈핏",
            "레귤러핏",
            "스탠다드핏",
            "세미오버핏",
            "세미와이드",
            "릴렉스핏",
            "컴포트핏",
            "머슬핏",
            "크롭핏",
            "박시핏",
            "슬림핏",
            "테이퍼드핏",

            // 소매·기장
            "긴팔",
            "반팔",
            "칠부",
            "오부",
            "민소매",
            "숏슬리브",
            "롱슬리브",
            "크롭",
            "숏",
            "롱",
            "미디",
            "맥시",
            "발목",
            "앵클",

            // 소재
            "코튼",
            "면",
            "린넨",
            "마",
            "울",
            "모직",
            "캐시미어",
            "니트",
            "폴리에스터",
            "나일론",
            "레이온",
            "비스코스",
            "스판",
            "스판덱스",
            "벨벳",
            "코듀로이",
            "골덴",
            "트위드",
            "가죽",
            "레더",
            "스웨이드",
            "메쉬",
            "플리스",
            "기모",
            "양털",

            // 디테일
            "카라",
            "라운드넥",
            "브이넥",
            "유넥",
            "헨리넥",
            "하이넥",
            "터틀넥",
            "집업",
            "지퍼",
            "버튼",
            "포켓",
            "스트링",
            "드로스트링",
            "밴딩",
            "핀턱",
            "플리츠",
            "셔링",
            "러플",
            "프릴",
            "슬릿",
            "절개",
            "워싱",
            "디스트로이드",
            "데미지",
            "패치",
            "자수",
            "프린트",
            "그래픽",
            "로고",

            // 기능·계절
            "여름",
            "겨울",
            "봄",
            "가을",
            "쿨링",
            "냉감",
            "발열",
            "보온",
            "방수",
            "발수",
            "방풍",
            "통기성",
            "속건",
            "기능성",
            "경량",
            "헤비웨이트"
    );

    private ProductNameSimilarity() {
    }

    static double calculate(
            String analyzedName,
            String productName
    ) {
        String normalizedAnalyzedName = normalize(analyzedName);
        String normalizedProductName = normalize(productName);

        if (normalizedAnalyzedName.isBlank()
                || normalizedProductName.isBlank()) {
            return 0.0;
        }

        double bigramScore = calculateBigramScore(
                normalizedAnalyzedName,
                normalizedProductName
        );

        double keywordScore = calculateKeywordScore(
                normalizedAnalyzedName,
                normalizedProductName
        );

        double finalScore = keywordScore * 0.7
                + bigramScore * 0.3;


        return finalScore;
    }

    private static double calculateBigramScore(
            String analyzedName,
            String productName
    ) {
        Set<String> analyzedBigrams = createBigrams(analyzedName);
        Set<String> productBigrams = createBigrams(productName);

        if (analyzedBigrams.isEmpty()
                || productBigrams.isEmpty()) {
            return analyzedName.equals(productName)
                    ? 1.0
                    : 0.0;
        }

        long matchedCount = analyzedBigrams.stream()
                .filter(productBigrams::contains)
                .count();

        return (2.0 * matchedCount)
                / (analyzedBigrams.size()
                + productBigrams.size());
    }

    private static double calculateKeywordScore(
            String analyzedName,
            String productName
    ) {
        Set<String> analyzedKeywords =
                extractKeywords(analyzedName);

        if (analyzedKeywords.isEmpty()) {
            return 0.0;
        }

        long matchedCount = analyzedKeywords.stream()
                .filter(productName::contains)
                .count();

        return (double) matchedCount
                / analyzedKeywords.size();
    }

    private static Set<String> extractKeywords(String name) {
        Set<String> keywords = new HashSet<>();

        for (String keyword : CLOTHING_KEYWORDS) {
            if (name.contains(keyword)) {
                keywords.add(keyword);
            }
        }

        return keywords;
    }

    private static String normalize(String name) {
        if (name == null) {
            return "";
        }

        return name
                .replaceAll("\\([^)]*\\)", "")
                .replace("\uB9C8\uCD08", "")
                .replace("UNIQLO", "")
                .replace("Uniqlo", "")
                .replaceAll(
                        "[^\\p{IsHangul}a-zA-Z0-9]",
                        ""
                )
                .toLowerCase(Locale.ROOT);
    }

    private static Set<String> createBigrams(String value) {
        Set<String> bigrams = new HashSet<>();

        for (int index = 0;
             index < value.length() - 1;
             index++) {
            bigrams.add(
                    value.substring(index, index + 2)
            );
        }

        return bigrams;
    }
}
