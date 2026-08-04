package com.wearly.infra.airkorea;

import com.wearly.domain.weather.exception.WeatherErrorCode;
import com.wearly.domain.weather.exception.WeatherException;
import com.wearly.infra.airkorea.dto.AirKoreaMeasureResponse;
import com.wearly.infra.airkorea.dto.AirKoreaStationResponse;
import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;

@Component
public class AirKoreaApiClient {

    private static final String STATION_LIST_URI =
            "/MsrstnInfoInqireSvc/getMsrstnList";
    private static final String MEASURE_URI =
            "/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty";

    private static final String SUCCESS_RESULT_CODE = "00";

    private static final int STATION_PAGE_SIZE = 1000;
    private static final int MAX_RESPONSE_SIZE = 4 * 1024 * 1024;

    private final WebClient webClient;
    private final AirKoreaApiProperties airKoreaApiProperties;

    public AirKoreaApiClient(
            WebClient.Builder webClientBuilder,
            AirKoreaApiProperties airKoreaApiProperties
    ) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 3000)
                .responseTimeout(Duration.ofSeconds(5))
                .doOnConnected(connection -> connection
                        .addHandlerLast(new ReadTimeoutHandler(5))
                        .addHandlerLast(new WriteTimeoutHandler(5)));

        ExchangeStrategies exchangeStrategies = ExchangeStrategies.builder()
                .codecs(configurer -> configurer
                        .defaultCodecs()
                        .maxInMemorySize(MAX_RESPONSE_SIZE))
                .build();

        this.webClient = webClientBuilder
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .exchangeStrategies(exchangeStrategies)
                .build();

        this.airKoreaApiProperties = airKoreaApiProperties;
    }

    public List<AirKoreaStationResponse.StationItem> getStations() {
        String url = airKoreaApiProperties.getBaseUrl()
                + STATION_LIST_URI
                + "?serviceKey=" + airKoreaApiProperties.getKey()
                + "&returnType=json"
                + "&numOfRows=" + STATION_PAGE_SIZE
                + "&pageNo=1";

        AirKoreaStationResponse response = request(
                url,
                AirKoreaStationResponse.class
        );

        if (response == null
                || response.getResponse() == null
                || response.getResponse().getHeader() == null
                || response.getResponse().getBody() == null
                || response.getResponse().getBody().getItems() == null) {
            throw new WeatherException(
                    WeatherErrorCode.AIR_QUALITY_API_ERROR
            );
        }

        validateResultCode(
                response.getResponse().getHeader().getResultCode()
        );

        return response.getResponse().getBody().getItems();
    }

    public AirKoreaMeasureResponse.MeasureItem getMeasure(String stationName) {
        String encodedStationName = URLEncoder.encode(
                stationName,
                StandardCharsets.UTF_8
        );

        String url = airKoreaApiProperties.getBaseUrl()
                + MEASURE_URI
                + "?serviceKey=" + airKoreaApiProperties.getKey()
                + "&returnType=json"
                + "&stationName=" + encodedStationName
                + "&dataTerm=DAILY"
                + "&ver=1.3"
                + "&numOfRows=1"
                + "&pageNo=1";

        AirKoreaMeasureResponse response = request(
                url,
                AirKoreaMeasureResponse.class
        );

        if (response == null
                || response.getResponse() == null
                || response.getResponse().getHeader() == null
                || response.getResponse().getBody() == null
                || response.getResponse().getBody().getItems() == null) {
            throw new WeatherException(
                    WeatherErrorCode.AIR_QUALITY_API_ERROR
            );
        }

        validateResultCode(
                response.getResponse().getHeader().getResultCode()
        );

        List<AirKoreaMeasureResponse.MeasureItem> items =
                response.getResponse().getBody().getItems();

        if (items.isEmpty()) {
            return null;
        }

        return items.getFirst();
    }

    private void validateResultCode(String resultCode) {
        if (!SUCCESS_RESULT_CODE.equals(resultCode)) {
            throw new WeatherException(
                    WeatherErrorCode.AIR_QUALITY_API_ERROR
            );
        }
    }

    private <T> T request(String url, Class<T> responseType) {
        return webClient.get()
                .uri(URI.create(url))
                .retrieve()
                .bodyToMono(responseType)
                .block();
    }
}
