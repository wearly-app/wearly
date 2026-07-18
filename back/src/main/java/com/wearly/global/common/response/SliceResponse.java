package com.wearly.global.common.response;

import lombok.Builder;
import lombok.Getter;
import org.springframework.data.domain.Slice;

import java.util.List;

@Getter
@Builder
public class SliceResponse<T> {

    private List<T> content;
    private int page;
    private int size;
    private boolean first;
    private boolean last;
    private boolean hasNext;

    public static <T> SliceResponse<T> of(List<T> content, Slice<?> slice) {
        return SliceResponse.<T>builder()
                .content(content)
                .page(slice.getNumber())
                .size(slice.getSize())
                .first(slice.isFirst())
                .last(slice.isLast())
                .hasNext(slice.hasNext())
                .build();
    }
}
