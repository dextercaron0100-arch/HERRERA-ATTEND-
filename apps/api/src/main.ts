import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import helmet from 'helmet';
import { randomUUID } from 'node:crypto';
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.use(helmet({ contentSecurityPolicy: process.env.NODE_ENV === 'production' ? undefined : false }));
  app.use((request: { headers: Record<string,string|undefined> }, response: { setHeader(name:string,value:string):void }, next:()=>void) => {
    const requestId = request.headers['x-request-id'] || randomUUID();
    request.headers['x-request-id'] = requestId;
    response.setHeader('x-request-id', requestId);
    next();
  });
  const origins = (process.env.CORS_ORIGINS ?? 'http://localhost:3000,http://localhost:3001').split(',').map(value => value.trim());
  app.enableCors({ origin: origins, credentials: true, methods: ['GET','POST','PATCH','DELETE','OPTIONS'] });
  app.useGlobalPipes(new ValidationPipe({ whitelist:true, forbidNonWhitelisted:true, transform:true }));
  const doc = SwaggerModule.createDocument(app, new DocumentBuilder().setTitle('GeoAttend API').setVersion('0.1').build());
  SwaggerModule.setup('docs', app, doc);
  await app.listen(Number(process.env.PORT ?? 4000));
}
bootstrap();
