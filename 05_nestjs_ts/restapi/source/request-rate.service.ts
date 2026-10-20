import { Injectable } from '@nestjs/common';

const bucketCount = 60;

@Injectable()
export class RequestRateService {
  private readonly buckets = Array.from({ length: bucketCount }, () => ({
    second: 0,
    count: 0,
  }));

  record(): void {
    const second = Math.floor(Date.now() / 1000);
    const bucket = this.buckets[second % bucketCount];

    if (bucket.second !== second) {
      bucket.second = second;
      bucket.count = 0;
    }

    bucket.count += 1;
  }

  getRequestsPerSecond(): number {
    const currentSecond = Math.floor(Date.now() / 1000);
    let requestCount = 0;

    for (const bucket of this.buckets) {
      if (currentSecond - bucket.second < bucketCount) {
        requestCount += bucket.count;
      }
    }

    return requestCount / bucketCount;
  }
}
