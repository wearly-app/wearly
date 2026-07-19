package com.wearly.infra.rembg;

import com.wearly.domain.clothes.exception.ClothesErrorCode;
import com.wearly.domain.clothes.exception.ClothesException;
import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;

@Component
public class RembgApiClient {

    private static final String REMOVE_BACKGROUND_URI = "/remove-background";
    private static final int MAX_RESPONSE_SIZE = 20 * 1024 * 1024;

    private final WebClient webClient;

    public RembgApiClient(
            WebClient.Builder webClientBuilder,
            RembgApiProperties rembgApiProperties
    ) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 3000)
                .responseTimeout(Duration.ofSeconds(60))
                .doOnConnected(connection -> connection
                        .addHandlerLast(new ReadTimeoutHandler(60))
                        .addHandlerLast(new WriteTimeoutHandler(60)));

        ExchangeStrategies exchangeStrategies = ExchangeStrategies.builder()
                .codecs(configurer -> configurer
                        .defaultCodecs()
                        .maxInMemorySize(MAX_RESPONSE_SIZE))
                .build();

        this.webClient = webClientBuilder
                .baseUrl(rembgApiProperties.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .exchangeStrategies(exchangeStrategies)
                .build();
    }

    public byte[] removeBackground(
            byte[] imageBytes,
            String fileName,
            String contentType
    ) {
        ByteArrayResource imageResource = new ByteArrayResource(imageBytes) {
            @Override
            public String getFilename() {
                return fileName;
            }
        };

        HttpHeaders imageHeaders = new HttpHeaders();
        imageHeaders.setContentType(
                MediaType.parseMediaType(contentType)
        );

        HttpEntity<ByteArrayResource> imagePart = new HttpEntity<>(
                imageResource,
                imageHeaders
        );

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("image", imagePart);

        return webClient.post()
                .uri(REMOVE_BACKGROUND_URI)
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(BodyInserters.fromMultipartData(body))
                .retrieve()
                .onStatus(
                        HttpStatusCode::is4xxClientError,
                        response -> Mono.error(
                                new ClothesException(
                                        ClothesErrorCode.INVALID_CLOTHES_IMAGE
                                )
                        )
                )
                .onStatus(
                        HttpStatusCode::is5xxServerError,
                        response -> Mono.error(
                                new ClothesException(
                                        ClothesErrorCode.REMBG_SERVICE_ERROR
                                )
                        )
                )
                .bodyToMono(byte[].class)
                .block();
    }
}
