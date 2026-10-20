import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { AppController } from './app.controller';
import { RequestRateInterceptor } from './request-rate.interceptor';
import { RequestRateService } from './request-rate.service';

@Module({
  controllers: [AppController],
  providers: [
    RequestRateService,
    {
      provide: APP_INTERCEPTOR,
      useClass: RequestRateInterceptor,
    },
  ],
})
export class AppModule {}
