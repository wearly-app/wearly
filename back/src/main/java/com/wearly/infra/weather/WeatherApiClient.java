package com.wearly.infra.weather;

import com.wearly.domain.weather.exception.WeatherErrorCode;
import com.wearly.domain.weather.exception.WeatherException;
import com.wearly.infra.weather.dto.OpenWeatherResponse;
import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;

@Component
public class WeatherApiClient {

    private static final String CURRENT_WEATHER_URI = "/data/2.5/weather";

    private final WebClient webClient;
    private final WeatherApiProperties weatherApiProperties;

    public WeatherApiClient(
            WebClient.Builder webClientBuilder,
            WeatherApiProperties weatherApiProperties
    ) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 3000)
                .responseTimeout(Duration.ofSeconds(5))
                .doOnConnected(connection -> connection
                        .addHandlerLast(new ReadTimeoutHandler(5))
                        .addHandlerLast(new WriteTimeoutHandler(5)));

        this.webClient = webClientBuilder
                .baseUrl(weatherApiProperties.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .build();

        this.weatherApiProperties = weatherApiProperties;
    }

    public OpenWeatherResponse getCurrentWeather(
            Double latitude,
            Double longitude
    ) {
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path(CURRENT_WEATHER_URI)
                        .queryParam("lat", latitude)
                        .queryParam("lon", longitude)
                        .queryParam("appid", weatherApiProperties.getKey())
                        .queryParam("units", "metric")
                        .queryParam("lang", "kr")
                        .build())
                .retrieve()
                .onStatus(
                        status -> status.value() == 401,
                        response -> Mono.error(
                                new WeatherException(
                                        WeatherErrorCode.INVALID_WEATHER_API_KEY
                                )
                        )
                )
                .onStatus(
                        HttpStatusCode::is4xxClientError,
                        response -> Mono.error(
                                new WeatherException(
                                        WeatherErrorCode.INVALID_LOCATION
                                )
                        )
                )
                .onStatus(
                        HttpStatusCode::is5xxServerError,
                        response -> Mono.error(
                                new WeatherException(
                                        WeatherErrorCode.WEATHER_API_ERROR
                                )
                        )
                )
                .bodyToMono(OpenWeatherResponse.class)
                .block();
    }
}
