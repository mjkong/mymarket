package org.mjkong.fabric.sample.api.support;

import lombok.*;

import javax.validation.constraints.NotNull;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class APIResponse {
    private String data;
//    private List<String> errors;
}
