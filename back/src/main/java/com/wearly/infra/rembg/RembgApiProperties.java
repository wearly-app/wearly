package com.wearly.infra.rembg;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "rembg.api")
public class RembgApiProperties {

    private String baseUrl;
}
