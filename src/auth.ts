import { betterAuth } from 'better-auth';
import { Pool } from 'pg';
import sql from './infrastructure/db/client';

const socialProviders: Record<string, any> = {};

if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
  socialProviders.google = {
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  };
}
if (process.env.GITHUB_CLIENT_ID && process.env.GITHUB_CLIENT_SECRET) {
  socialProviders.github = {
    clientId: process.env.GITHUB_CLIENT_ID,
    clientSecret: process.env.GITHUB_CLIENT_SECRET,
  };
}

export const auth = betterAuth({
  database: new Pool({
    connectionString: process.env.DATABASE_URL!,
  }),
  secret: process.env.BETTER_AUTH_SECRET || 'fallback-secret-for-testing-only-1234567890',
  baseURL: process.env.BETTER_AUTH_URL || 'http://localhost:3000',
  trustedOrigins: process.env.TRUSTED_ORIGINS
    ? process.env.TRUSTED_ORIGINS.split(',')
    : ['http://localhost:5173'],
  emailAndPassword: {
    enabled: true,
  },
  socialProviders,
  databaseHooks: {
    user: {
      create: {
        after: async (user) => {
          // Insert 25 default categories with llm_description
          const defaultCategories = [
            { name: 'biedronka', is_fixed_cost: false, llm_description: 'purchases at Biedronka grocery store' },
            { name: 'żabka', is_fixed_cost: false, llm_description: 'purchases at Żabka convenience store' },
            { name: 'paliwo', is_fixed_cost: true, llm_description: 'fuel stations only — ORLEN, SHELL, BP, Moya, Lotos, any stacja paliw; NOT parking or car wash' },
            { name: 'taxi', is_fixed_cost: false, llm_description: 'taxi rides, Uber, Bolt, FreeNow' },
            { name: 'fun', is_fixed_cost: false, llm_description: 'discretionary entertainment not covered by other categories — cinema, concerts, clubs, hobby shops, AliExpress, sport events' },
            { name: 'VAT', is_fixed_cost: true, llm_description: 'VAT tax payments to Urząd Skarbowy (title contains VAT7 or VAT)' },
            { name: 'PIT36', is_fixed_cost: true, llm_description: 'income tax payments to Urząd Skarbowy (title contains PIT36, PIT4R, or PPE)' },
            { name: 'ZUS', is_fixed_cost: true, llm_description: 'payments to Zakład Ubezpieczeń Społecznych — social insurance, ubezpieczenie zdrowotne' },
            { name: 'auto', is_fixed_cost: false, llm_description: 'all car expenses EXCEPT fuel — Arval leasing, parking, car wash, oil changes, repairs, tyres, toll roads (A1, A4, viaTOLL)' },
            { name: 'biuro', is_fixed_cost: true, llm_description: 'JDG business expenses — P4 mobile, Orange telecom, Kancelaria Podatkowo-Gospodarcza accounting firm, business software/subscriptions' },
            { name: 'mieszkanie', is_fixed_cost: true, llm_description: 'rent and household bills — payments to Marta Szczygiel, electricity, water, cleaning services' },
            { name: 'przejazdy', is_fixed_cost: false, llm_description: 'city public transport only — MPK, ZTM, SKM, PKP trains, intercity buses' },
            { name: 'kawa', is_fixed_cost: false, llm_description: 'coffee shops (Ziomal, Starbucks, Costa) and online coffee orders to All Good or Konesso' },
            { name: 'kredyt', is_fixed_cost: true, llm_description: 'monthly loan instalment to Santander (~200 PLN)' },
            { name: 'lidl', is_fixed_cost: false, llm_description: 'purchases at Lidl grocery store' },
            { name: 'ubrania', is_fixed_cost: false, llm_description: 'clothing — Uniqlo, TK Maxx, eobuwie, and similar clothing/shoe stores' },
            { name: 'rossman', is_fixed_cost: false, llm_description: 'Rossmann drugstore specifically' },
            { name: 'apteka', is_fixed_cost: false, llm_description: 'pharmacies — Ziko, Dr. Max, and any payee with "apteka" in name; NOT Rossmann' },
            { name: 'lekarz', is_fixed_cost: false, llm_description: 'doctor visits, clinics, pracownia psychologiczna, medical laboratories' },
            { name: 'kluska', is_fixed_cost: false, llm_description: 'veterinary expenses (dog named Kluska) — any vet clinic or pet medical cost' },
            { name: 'krypto', is_fixed_cost: false, llm_description: 'cryptocurrency platforms — Swissborg, MetaMask, Binance, BitBay, and similar' },
            { name: 'inwestycje', is_fixed_cost: false, llm_description: 'investment transfers only — Dom Maklerski BOS, PKO Biuro Maklerskie, DM BOS' },
            { name: 'prezenty', is_fixed_cost: false, llm_description: 'gifts — jewellery stores (Tous), flowers, one-off gift purchases' },
            { name: 'restauracje', is_fixed_cost: false, llm_description: 'restaurants (Loro, Mokra Włoszka, etc.) and food delivery (Wolt, Uber Eats, Pyszne.pl)' },
            { name: 'foto', is_fixed_cost: false, llm_description: 'photography equipment, photo studio, camera purchases' },
          ];

          for (const cat of defaultCategories) {
            await sql`
              INSERT INTO categories (name, is_fixed_cost, user_id, llm_description)
              VALUES (${cat.name}, ${cat.is_fixed_cost}, ${user.id}, ${cat.llm_description})
            `;
          }

          // Insert default accounts
          await sql`
            INSERT INTO accounts (name, type, user_id)
            VALUES ('ING Business', 'business', ${user.id})
          `;
          await sql`
            INSERT INTO accounts (name, type, user_id)
            VALUES ('IPKO Personal', 'personal', ${user.id})
          `;
        },
      },
    },
  },
});
