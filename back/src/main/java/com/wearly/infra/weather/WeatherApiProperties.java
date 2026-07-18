package com.wearly.infra.weather;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "weather.api")
public class WeatherApiProperties {

    private String key;
    private String baseUrl;
}
