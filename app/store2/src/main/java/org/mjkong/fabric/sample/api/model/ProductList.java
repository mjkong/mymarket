package org.mjkong.fabric.sample.api.model;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonPOJOBuilder;
import lombok.*;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@JsonDeserialize(builder = ProductList.ProductListBuilder.class)
@Builder(toBuilder = true)
public class ProductList {

    @Singular("products")
    private List<ProductRecord> productList = new ArrayList<>();

    @JsonPOJOBuilder(withPrefix = "")
    public static class ProductListBuilder {}


    public static void main(String[] args) throws IOException {
//        String jsonStr = "[{\"name\":\"MJ100\",\"qty\":\"300\",\"owner\":\"store2\"},{\"name\":\"MJ101\",\"qty\":\"300\",\"owner\":\"store2\"}]";
//        String productList = "{\"productList\":[{\"key\":\"\",\"record\":{\"name\":\"\",\"qty\":\"\",\"owner\":\"\"}},{\"key\":\"PD0\",\"record\":{\"name\":\"MJ100\",\"qty\":\"300\",\"owner\":\"store2\"}},{\"key\":\"PD1\",\"record\":{\"name\":\"MJ101\",\"qty\":\"300\",\"owner\":\"store2\"}}]}";
//        String jsonStr = "{\"productList\":[{\"name\":\"A\",\"qty\":\"100\",\"owner\":\"B\"},{\"name\":\"B\",\"qty\":\"200\",\"owner\":\"B\"}]}";
        ObjectMapper mapper = new ObjectMapper();
//        mapper.readValue(productList, ProductList.class);

        ProductInfo pi1 = ProductInfo.builder().name("A").owner("B").qty("100").build();
        ProductInfo pi2 = ProductInfo.builder().name("B").owner("B").qty("200").build();
        ProductRecord p1 = ProductRecord.builder().key("PD01").record(pi1).build();
        ProductRecord p2 = ProductRecord.builder().key("PD02").record(pi2).build();

        List<ProductRecord> pList = new ArrayList<>();
        pList.add(p1);
        pList.add(p2);
        ProductList pl = ProductList.builder().productList(pList).build();

        System.out.println(mapper.writeValueAsString(pl));
        System.out.println("ttttt");
    }
}
