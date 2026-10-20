import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const port = Number(process.env.PORT ?? 80);
  const app = await NestFactory.create(AppModule);

  await app.listen(port);
  console.log(`Running on http://localhost:${port}`);
}

void bootstrap();
