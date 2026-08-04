package com.wearly.infra.airkorea;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "airkorea.api")
public class AirKoreaApiProperties {

    private String key;
    private String baseUrl;
}
