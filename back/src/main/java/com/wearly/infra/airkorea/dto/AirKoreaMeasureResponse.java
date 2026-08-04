package com.wearly.infra.airkorea.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AirKoreaMeasureResponse {

    private Response response;

    @Getter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Response {

        private Header header;
        private Body body;
    }

    @Getter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Header {

        private String resultCode;
        private String resultMsg;
    }

    @Getter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Body {

        private List<MeasureItem> items;
    }

    @Getter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MeasureItem {

        private String dataTime;

        private String pm10Value;
        private String pm25Value;

        private String pm10Grade1h;
        private String pm25Grade1h;

        private String pm10Grade;
        private String pm25Grade;

        private String pm10Flag;
        private String pm25Flag;
    }
}
