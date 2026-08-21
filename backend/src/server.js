import OpenAI from 'openai';
import { createApp } from './app.js';

const port = Number(process.env.PORT || 8080);
const openaiKey = process.env.OPENAI_API_KEY;
const clientToken = process.env.ROUTE_VISION_CLIENT_TOKEN;
const model = process.env.OPENAI_VISION_MODEL || 'gpt-5.4-mini';
const rateLimitPerMinute = Number(process.env.RATE_LIMIT_PER_MINUTE || 12);
const trustProxy = process.env.TRUST_PROXY === '1';

if (!openaiKey) throw new Error('OPENAI_API_KEY is required');
if (!clientToken || clientToken.length < 32) {
  throw new Error('ROUTE_VISION_CLIENT_TOKEN must be set to a random value of at least 32 characters');
}

const openai = new OpenAI({ apiKey: openaiKey });
const app = createApp({ openai, clientToken, model, rateLimitPerMinute, trustProxy });

app.listen(port, '0.0.0.0', () => {
  console.log(`route vision backend listening on ${port}`);
});
