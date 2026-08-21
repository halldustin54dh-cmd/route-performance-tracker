import assert from 'node:assert/strict';
import test from 'node:test';
import { createApp } from '../src/app.js';

const token = 'test-token-abcdefghijklmnopqrstuvwxyz-123456';
const image = { mimeType: 'image/png', base64: 'a'.repeat(64) };

async function withServer(app, fn) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const address = server.address();
  try {
    await fn(`http://127.0.0.1:${address.port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
}

function mockOpenAI(output) {
  return {
    responses: {
      create: async () => ({ output_text: JSON.stringify(output) }),
    },
  };
}

test('healthz is public and non-cacheable', async () => {
  const app = createApp({ openai: mockOpenAI({}), clientToken: token });
  await withServer(app, async (base) => {
    const response = await fetch(`${base}/healthz`);
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    assert.deepEqual(await response.json(), { ok: true });
  });
});

test('vision endpoint requires bearer token', async () => {
  const app = createApp({ openai: mockOpenAI({}), clientToken: token });
  await withServer(app, async (base) => {
    const response = await fetch(`${base}/v1/route-vision`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ images: [image] }),
    });
    assert.equal(response.status, 401);
    assert.deepEqual(await response.json(), { error: 'unauthorized' });
  });
});

test('vision endpoint rejects unsupported images', async () => {
  const app = createApp({ openai: mockOpenAI({}), clientToken: token });
  await withServer(app, async (base) => {
    const response = await fetch(`${base}/v1/route-vision`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ images: [{ mimeType: 'image/gif', base64: 'a'.repeat(64) }] }),
    });
    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: 'invalid_images' });
  });
});

test('vision output is normalized and clamped', async () => {
  let captured;
  const openai = {
    responses: {
      create: async (request) => {
        captured = request;
        return {
          output_text: JSON.stringify({
            routeSpread: 9,
            rurality: -2,
            clustering: 4.2,
            backtrackingRisk: 3,
            accessComplexity: 2,
            estimatedAverageDriveMinutes: 55,
            likelyRouteType: 'Mixed',
            summary: 'Route is widely distributed.',
            confidence: 1.4,
            signals: ['wide map extent', 'separate clusters'],
          }),
        };
      },
    },
  };
  const app = createApp({ openai, clientToken: token });
  await withServer(app, async (base) => {
    const response = await fetch(`${base}/v1/route-vision`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ images: [image], ocrText: 'Stops: 190' }),
    });
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    const body = await response.json();
    assert.equal(body.routeSpread, 5);
    assert.equal(body.rurality, 0);
    assert.equal(body.clustering, 4);
    assert.equal(body.estimatedAverageDriveMinutes, 30);
    assert.equal(body.confidence, 1);
    assert.equal(captured.store, false);
    assert.equal(captured.input[0].content.filter((part) => part.type === 'input_image').length, 1);
  });
});

test('rate limiting blocks excess requests', async () => {
  const app = createApp({ openai: mockOpenAI({ routeSpread: 1 }), clientToken: token, rateLimitPerMinute: 1 });
  await withServer(app, async (base) => {
    const init = {
      method: 'POST',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ images: [image] }),
    };
    assert.equal((await fetch(`${base}/v1/route-vision`, init)).status, 200);
    const second = await fetch(`${base}/v1/route-vision`, init);
    assert.equal(second.status, 429);
    assert.equal(second.headers.get('retry-after'), '60');
  });
});
