package com.wearly;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@EnableJpaAuditing
@SpringBootApplication
public class WearlyApplication {

    public static void main(String[] args) {
        SpringApplication.run(WearlyApplication.class, args);
    }

}
