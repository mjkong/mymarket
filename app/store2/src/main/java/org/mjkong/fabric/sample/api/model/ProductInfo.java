package org.mjkong.fabric.sample.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonPOJOBuilder;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@JsonDeserialize(builder = ProductInfo.ProductInfoBuilder.class)
@Builder(toBuilder = true)
public class ProductInfo {

    @JsonProperty
    private String name;

    @JsonProperty
    private String qty;

    @JsonProperty
    private String owner;

    @JsonPOJOBuilder(withPrefix = "")
    public static class ProductInfoBuilder {}

}
