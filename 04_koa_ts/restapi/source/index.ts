import Koa from 'koa';

const PORT = Number(process.env.PORT ?? 80);
const app = new Koa();

let requestCount = 0;

const wait = (milliseconds: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, milliseconds));

app.use(async (ctx) => {
  if (ctx.path === '/') {
    ctx.body = 'Koa sier "Hello Learniken Fordypning!\n';
    return;
  }

  if (ctx.path === '/healthz') {
    const delay = requestCount * 100;
    await wait(delay);
    ctx.status = 200;
    ctx.body = {
      status: 'UP',
      timestamp: new Date(),
      Requestcount: requestCount,
      Delay: delay,
    };
    return;
  }

  if (ctx.path === '/readyz') {
    ctx.status = 200;
    ctx.body = { status: 'UP' };
    return;
  }

  if (ctx.path === '/slow') {
    const requestedDelay = Number.parseInt(ctx.query.n as string, 10) || 100;
    requestCount += 1;
    const delay = requestCount * requestedDelay;
    ctx.body = `Request #${requestCount}, delayed by ${delay}ms\n`;
    return;
  }

  ctx.status = 404;
});

app.listen(PORT);
console.log(`Running on http://localhost:${PORT}`);
