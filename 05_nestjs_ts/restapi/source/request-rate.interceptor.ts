import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { RequestRateService } from './request-rate.service';

interface HttpRequest {
  url?: string;
}

@Injectable()
export class RequestRateInterceptor implements NestInterceptor {
  constructor(private readonly requestRate: RequestRateService) {}

  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<unknown> {
    const request = context.switchToHttp().getRequest<HttpRequest>();

    if (request.url !== '/metrics') {
      this.requestRate.record();
    }

    return next.handle();
  }
}
