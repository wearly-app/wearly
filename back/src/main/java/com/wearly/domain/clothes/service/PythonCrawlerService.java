package com.wearly.domain.clothes.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class PythonCrawlerService {

    private final ObjectMapper objectMapper;

    public Map<String, String> crawl(String targetUrl) {
        Map<String, String> result = new HashMap<>();
        try {
            // Encode the URL properly to avoid ProcessBuilder/Windows encoding issues with Korean characters
            String encodedUrl = targetUrl;
            if (targetUrl.contains("macho707.com") && !targetUrl.contains("%")) {
                int productIdx = targetUrl.indexOf("/product/");
                if (productIdx != -1) {
                    String baseUrl = targetUrl.substring(0, productIdx + 9);
                    String rest = targetUrl.substring(productIdx + 9);
                    String[] parts = rest.split("/");
                    for (int i = 0; i < parts.length; i++) {
                        parts[i] = java.net.URLEncoder.encode(parts[i], "UTF-8");
                    }
                    encodedUrl = baseUrl + String.join("/", parts) + (rest.endsWith("/") ? "/" : "");
                }
            }
            
            Path scriptPath = Paths.get(System.getProperty("user.dir"), "src", "main", "resources", "scripts", "crawler.py");
            
            ProcessBuilder pb = new ProcessBuilder(
                    "py",
                    scriptPath.toString(),
                    encodedUrl
            );
            pb.redirectErrorStream(true);
            Process process = pb.start();

            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line);
                }
            }

            int exitCode = process.waitFor();
            if (exitCode != 0) {
                log.error("Python crawler failed with exit code {}: {}", exitCode, output.toString());
                return null;
            }

            JsonNode rootNode = objectMapper.readTree(output.toString());
            if (rootNode.has("error")) {
                log.error("Python crawler error: {}", rootNode.get("error").asText());
                return null;
            }

            result.put("name", rootNode.path("name").asText(""));
            result.put("brand", rootNode.path("brand").asText("마초"));
            result.put("material", rootNode.path("material").asText("정보 없음"));
            result.put("fit", rootNode.path("fit").asText("정보 없음"));
            result.put("season", rootNode.path("season").asText("정보 없음"));
            result.put("bodyText", rootNode.path("bodyText").asText(""));
            
            return result;

        } catch (Exception e) {
            log.error("Error executing python crawler", e);
            return null;
        }
    }
}
