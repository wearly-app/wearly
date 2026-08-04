import re

with open("back/src/main/java/com/wearly/domain/clothes/controller/ClothesController.java", "r", encoding="utf-8") as f:
    content = f.read()

# Fix 1
content = re.sub(r"<<<<<<< HEAD\nimport com.wearly.domain.clothes.service.RembgService;\nimport com.wearly.domain.clothes.service.GeminiApiClient;\n=======\nimport com.wearly.domain.outfit.service.OutfitHistoryService;\n>>>>>>> origin/main",
"import com.wearly.domain.clothes.service.RembgService;\nimport com.wearly.domain.clothes.service.GeminiApiClient;\nimport com.wearly.domain.outfit.service.OutfitHistoryService;", content)

# Fix 2
content = re.sub(r"<<<<<<< HEAD\nimport com.wearly.domain.clothes.service.PythonCrawlerService;\nimport java.util.List;\nimport java.util.Map;\nimport java.io.ByteArrayInputStream;\nimport java.awt.image.BufferedImage;\nimport javax.imageio.ImageIO;\nimport java.awt.Color;\n\n=======\n>>>>>>> origin/main",
"import com.wearly.domain.clothes.service.PythonCrawlerService;\nimport java.util.List;\nimport java.util.Map;\nimport java.io.ByteArrayInputStream;\nimport java.awt.image.BufferedImage;\nimport javax.imageio.ImageIO;\nimport java.awt.Color;", content)

# Fix 3
content = re.sub(r"<<<<<<< HEAD\n    private final RembgService rembgService;\n    private final GeminiApiClient geminiApiClient;\n    private final PythonCrawlerService pythonCrawlerService;\n=======\n    private final OutfitHistoryService outfitHistoryService;\n    private final S3ImageStorage s3ImageStorage;\n>>>>>>> origin/main",
"    private final RembgService rembgService;\n    private final GeminiApiClient geminiApiClient;\n    private final PythonCrawlerService pythonCrawlerService;\n    private final OutfitHistoryService outfitHistoryService;\n    private final S3ImageStorage s3ImageStorage;", content)

# Fix 4: The huge block at the end
content = content.replace("=======\n        String imageKey = s3ImageStorage.upload(image);\n\n        ClothesAnalyzeResponse response = ClothesAnalyzeResponse.builder()\n                .imageUrl(imageKey)\n                .build();\n        // TODO: rembg 배경제거 + Vision API 연동 후 category/style/color/brand/material/thickness/cloValue 채우기\n\n        return ResponseEntity.ok(response);\n>>>>>>> origin/main", "")
content = content.replace("<<<<<<< HEAD\n        try {", "        try {")


with open("back/src/main/java/com/wearly/domain/clothes/controller/ClothesController.java", "w", encoding="utf-8") as f:
    f.write(content)
