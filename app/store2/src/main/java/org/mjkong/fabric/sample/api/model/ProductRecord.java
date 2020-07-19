package org.mjkong.fabric.sample.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonPOJOBuilder;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@JsonDeserialize(builder = ProductRecord.ProductRecordBuilder.class)
@Builder(toBuilder = true)
public class ProductRecord {

    @JsonProperty
    String key;

    @JsonProperty
    ProductInfo record;

    @JsonPOJOBuilder(withPrefix = "")
    public static class ProductRecordBuilder {}
}
