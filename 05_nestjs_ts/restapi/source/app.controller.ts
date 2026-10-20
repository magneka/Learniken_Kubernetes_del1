import {
  Controller,
  Get,
  Header,
  Query,
} from '@nestjs/common';
import { RequestRateService } from './request-rate.service';

interface HealthResponse {
  status: 'UP';
  timestamp: Date;
  Requestcount: number;
  Delay: number;
}

let requestCount = 0;

const wait = (milliseconds: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, milliseconds));

@Controller()
export class AppController {
  constructor(private readonly requestRate: RequestRateService) {}

  @Get()
  getRoot(): string {
    return 'NestJS sier "Hello Learniken Fordypning!\n';
  }

  @Get('healthz')
  async getHealth(): Promise<HealthResponse> {
    const delay = requestCount * 100;
    await wait(delay);

    return {
      status: 'UP',
      timestamp: new Date(),
      Requestcount: requestCount,
      Delay: delay,
    };
  }

  @Get('readyz')
  getReadiness(): { status: 'UP' } {
    return { status: 'UP' };
  }

  @Get('metrics')
  @Header('Content-Type', 'text/plain; version=0.0.4')
  getMetrics(): string {
    const requestsPerSecond = this.requestRate
      .getRequestsPerSecond()
      .toFixed(3);

    return [
      '# HELP requests_per_second Average requests per second received by this Pod over the last 60 seconds.',
      '# TYPE requests_per_second gauge',
      `requests_per_second ${requestsPerSecond}`,
      '',
    ].join('\n');
  }

  @Get('slow')
  getSlow(@Query('n') value?: string): string {
    const requestedDelay = Number.parseInt(value ?? '', 10) || 100;
    requestCount += 1;
    const delay = requestCount * requestedDelay;

    return `Request #${requestCount}, delayed by ${delay}ms\n`;
  }
}
