package com.learniken.springrest;

import org.springframework.stereotype.Component;
import java.util.concurrent.atomic.AtomicLong;

@Component
public class RequestCounter {
    private final AtomicLong requestCount = new AtomicLong(0);

    public long getCount() {
        return requestCount.get();
    }

    public long incrementAndGet() {
        return requestCount.incrementAndGet();
    }
}
