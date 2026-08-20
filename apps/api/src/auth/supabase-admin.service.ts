import { BadGatewayException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { createClient, type SupabaseClient, type User } from '@supabase/supabase-js';

@Injectable()
export class SupabaseAdminService {
  private readonly client: SupabaseClient | null;

  constructor() {
    const url = process.env.SUPABASE_URL?.replace(/\/$/u, '');
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    this.client = url && serviceRoleKey
      ? createClient(url, serviceRoleKey, {
          auth: { autoRefreshToken: false, persistSession: false },
        })
      : null;
  }

  async resolveUserId(authUserId: string | null, email: string): Promise<string> {
    if (authUserId) return authUserId;
    const client = this.requireClient();
    const normalizedEmail = email.trim().toLowerCase();
    const perPage = 200;

    for (let page = 1; page <= 50; page += 1) {
      const { data, error } = await client.auth.admin.listUsers({ page, perPage });
      if (error) throw new BadGatewayException('Unable to look up the employee login account');
      const match = data.users.find((user: User) => user.email?.trim().toLowerCase() === normalizedEmail);
      if (match) return match.id;
      if (data.users.length < perPage) break;
    }

    throw new NotFoundException('No Supabase login account exists for this employee email');
  }

  async updatePassword(userId: string, password: string): Promise<void> {
    const { error } = await this.requireClient().auth.admin.updateUserById(userId, { password });
    if (error) throw new BadGatewayException('Unable to update the password for this account');
  }

  private requireClient(): SupabaseClient {
    if (!this.client) {
      throw new ServiceUnavailableException('Supabase password administration is not configured');
    }
    return this.client;
  }
}
