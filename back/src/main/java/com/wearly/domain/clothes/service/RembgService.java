package com.wearly.domain.clothes.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

@Slf4j
@Service
public class RembgService {

    private Path scriptPath;

    public RembgService() {
        // Initialize and prepare the script.
        // We attempt to find the script in the local development resources folder.
        // If not found (e.g. running packaged), we extract it from resources.
        try {
            Path devPath = Path.of("src/main/resources/scripts/remove_bg.py");
            if (Files.exists(devPath)) {
                this.scriptPath = devPath.toAbsolutePath();
                log.info("Rembg script located at: {}", this.scriptPath);
            } else {
                // Fallback: Copy from resource jar to temp file
                Path tempDir = Files.createTempDirectory("wearly-scripts");
                Path tempScript = tempDir.resolve("remove_bg.py");
                try (InputStream is = getClass().getResourceAsStream("/scripts/remove_bg.py")) {
                    if (is == null) {
                        throw new FileNotFoundException("remove_bg.py not found in resources");
                    }
                    Files.copy(is, tempScript, StandardCopyOption.REPLACE_EXISTING);
                    this.scriptPath = tempScript.toAbsolutePath();
                    log.info("Rembg script extracted to temp file: {}", this.scriptPath);
                }
            }
        } catch (IOException e) {
            log.error("Failed to initialize RembgService script", e);
        }
    }

    public byte[] removeBackground(byte[] inputBytes) {
        if (scriptPath == null) {
            log.error("Rembg script path is not initialized");
            return inputBytes; // fallback to original
        }

        Path tempInput = null;
        Path tempOutput = null;
        try {
            // Create temporary files
            tempInput = Files.createTempFile("rembg-in", ".png");
            tempOutput = Files.createTempFile("rembg-out", ".png");

            Files.write(tempInput, inputBytes);

            // Execute: py <script> <input> <output>
            ProcessBuilder pb = new ProcessBuilder(
                    "py",
                    scriptPath.toString(),
                    tempInput.toAbsolutePath().toString(),
                    tempOutput.toAbsolutePath().toString()
            );
            pb.redirectErrorStream(true);
            Process process = pb.start();

            // Read execution output
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[rembg python] {}", line);
                }
            }

            int exitCode = process.waitFor();
            if (exitCode == 0 && Files.exists(tempOutput) && Files.size(tempOutput) > 0) {
                log.info("Rembg background removal succeeded.");
                return Files.readAllBytes(tempOutput);
            } else {
                log.error("Rembg script failed with exit code: {}", exitCode);
            }
        } catch (Exception e) {
            log.error("Error executing background removal script", e);
        } finally {
            // Clean up temp files
            deleteFile(tempInput);
            deleteFile(tempOutput);
        }

        return inputBytes; // Return original on failure
    }

    private void deleteFile(Path path) {
        if (path != null) {
            try {
                Files.deleteIfExists(path);
            } catch (IOException e) {
                log.warn("Failed to delete temp file: {}", path, e);
            }
        }
    }
}
