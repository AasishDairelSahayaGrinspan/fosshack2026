import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export const databaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: configService.get<string>('DB_HOST', 'localhost'),
  port: configService.get<number>('DB_PORT', 5432),
  username: configService.get<string>('DB_USER', 'unravel'),
  password: configService.get<string>('DB_PASS', 'unravel'),
  database: configService.get<string>('DB_NAME', 'unravel'),
  autoLoadEntities: true,
  synchronize: configService.get<string>('NODE_ENV') !== 'production',
});
