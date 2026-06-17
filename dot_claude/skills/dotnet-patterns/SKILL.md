---
name: dotnet-patterns
description: Idiomatic C# and .NET patterns, conventions, dependency injection, async/await, and best practices for building robust, maintainable .NET applications.
---

# .NET 開発パターン

堅牢かつ高性能で保守しやすいアプリケーションを構築するための、イディオマティックな C# と .NET のパターンです。

## 有効化のタイミング

- 新しい C# コードを書くとき
- C# コードをレビューするとき
- 既存の .NET アプリケーションをリファクタリングするとき
- ASP.NET Core でサービスアーキテクチャを設計するとき

## 基本原則

### 1. イミュータビリティを優先する

データモデルには record と init 専用プロパティを使うこと。ミュータブルにするのは、明示的で正当な理由がある場合に限ること。

```csharp
// 推奨: イミュータブルな値オブジェクト
public sealed record Money(decimal Amount, string Currency);

// 推奨: init セッターを持つイミュータブルな DTO
public sealed class CreateOrderRequest
{
    public required string CustomerId { get; init; }
    public required IReadOnlyList<OrderItem> Items { get; init; }
}

// 非推奨: public セッターを持つミュータブルなモデル
public class Order
{
    public string CustomerId { get; set; }
    public List<OrderItem> Items { get; set; }
}
```

### 2. 暗黙より明示

null 許容性、アクセス修飾子、意図を明確にすること。

```csharp
// 推奨: 明示的なアクセス修飾子と null 許容性
public sealed class UserService
{
    private readonly IUserRepository _repository;
    private readonly ILogger<UserService> _logger;

    public UserService(IUserRepository repository, ILogger<UserService> logger)
    {
        _repository = repository ?? throw new ArgumentNullException(nameof(repository));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<User?> FindByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return await _repository.FindByIdAsync(id, cancellationToken);
    }
}
```

### 3. 抽象に依存する

サービス境界にはインターフェースを使うこと。DI コンテナ経由で登録すること。

```csharp
// 推奨: インターフェースに基づく依存
public interface IOrderRepository
{
    Task<Order?> FindByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<IReadOnlyList<Order>> FindByCustomerAsync(string customerId, CancellationToken cancellationToken);
    Task AddAsync(Order order, CancellationToken cancellationToken);
}

// 登録
builder.Services.AddScoped<IOrderRepository, SqlOrderRepository>();
```

## async/await パターン

### 適切な async の使い方

```csharp
// 推奨: 末端まで async、CancellationToken 付き
public async Task<OrderSummary> GetOrderSummaryAsync(
    Guid orderId,
    CancellationToken cancellationToken)
{
    var order = await _repository.FindByIdAsync(orderId, cancellationToken)
        ?? throw new NotFoundException($"Order {orderId} not found");

    var customer = await _customerService.GetAsync(order.CustomerId, cancellationToken);

    return new OrderSummary(order, customer);
}

// 非推奨: async をブロックする
public OrderSummary GetOrderSummary(Guid orderId)
{
    var order = _repository.FindByIdAsync(orderId, CancellationToken.None).Result; // デッドロックのリスク
    return new OrderSummary(order);
}
```

### 並列の async 処理

```csharp
// 推奨: 独立した処理を並行実行する
public async Task<DashboardData> LoadDashboardAsync(CancellationToken cancellationToken)
{
    var ordersTask = _orderService.GetRecentAsync(cancellationToken);
    var metricsTask = _metricsService.GetCurrentAsync(cancellationToken);
    var alertsTask = _alertService.GetActiveAsync(cancellationToken);

    await Task.WhenAll(ordersTask, metricsTask, alertsTask);

    return new DashboardData(
        Orders: await ordersTask,
        Metrics: await metricsTask,
        Alerts: await alertsTask);
}
```

## Options パターン

設定セクションを強く型付けされたオブジェクトにバインドすること。

```csharp
public sealed class SmtpOptions
{
    public const string SectionName = "Smtp";

    public required string Host { get; init; }
    public required int Port { get; init; }
    public required string Username { get; init; }
    public bool UseSsl { get; init; } = true;
}

// 登録
builder.Services.Configure<SmtpOptions>(
    builder.Configuration.GetSection(SmtpOptions.SectionName));

// インジェクション経由での使用例
public class EmailService(IOptions<SmtpOptions> options)
{
    private readonly SmtpOptions _smtp = options.Value;
}
```

## Result パターン

想定内の失敗に対しては例外をスローせず、明示的に成功／失敗を返すこと。

```csharp
public sealed record Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string? Error { get; }

    private Result(T value) { IsSuccess = true; Value = value; }
    private Result(string error) { IsSuccess = false; Error = error; }

    public static Result<T> Success(T value) => new(value);
    public static Result<T> Failure(string error) => new(error);
}

// 使用例
public async Task<Result<Order>> PlaceOrderAsync(CreateOrderRequest request)
{
    if (request.Items.Count == 0)
        return Result<Order>.Failure("Order must contain at least one item");

    var order = Order.Create(request);
    await _repository.AddAsync(order, CancellationToken.None);
    return Result<Order>.Success(order);
}
```

## EF Core を用いた Repository パターン

```csharp
public sealed class SqlOrderRepository : IOrderRepository
{
    private readonly AppDbContext _db;

    public SqlOrderRepository(AppDbContext db) => _db = db;

    public async Task<Order?> FindByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return await _db.Orders
            .Include(o => o.Items)
            .AsNoTracking()
            .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);
    }

    public async Task<IReadOnlyList<Order>> FindByCustomerAsync(
        string customerId,
        CancellationToken cancellationToken)
    {
        return await _db.Orders
            .Where(o => o.CustomerId == customerId)
            .OrderByDescending(o => o.CreatedAt)
            .AsNoTracking()
            .ToListAsync(cancellationToken);
    }

    public async Task AddAsync(Order order, CancellationToken cancellationToken)
    {
        _db.Orders.Add(order);
        await _db.SaveChangesAsync(cancellationToken);
    }
}
```

## ミドルウェアとパイプライン

```csharp
// カスタムミドルウェア
public sealed class RequestTimingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestTimingMiddleware> _logger;

    public RequestTimingMiddleware(RequestDelegate next, ILogger<RequestTimingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            _logger.LogInformation(
                "Request {Method} {Path} completed in {ElapsedMs}ms with status {StatusCode}",
                context.Request.Method,
                context.Request.Path,
                stopwatch.ElapsedMilliseconds,
                context.Response.StatusCode);
        }
    }
}
```

## Minimal API パターン

```csharp
// ルートグループで整理する
var orders = app.MapGroup("/api/orders")
    .RequireAuthorization()
    .WithTags("Orders");

orders.MapGet("/{id:guid}", async (
    Guid id,
    IOrderRepository repository,
    CancellationToken cancellationToken) =>
{
    var order = await repository.FindByIdAsync(id, cancellationToken);
    return order is not null
        ? TypedResults.Ok(order)
        : TypedResults.NotFound();
});

orders.MapPost("/", async (
    CreateOrderRequest request,
    IOrderService service,
    CancellationToken cancellationToken) =>
{
    var result = await service.PlaceOrderAsync(request, cancellationToken);
    return result.IsSuccess
        ? TypedResults.Created($"/api/orders/{result.Value!.Id}", result.Value)
        : TypedResults.BadRequest(result.Error);
});
```

## ガード節

```csharp
// 推奨: 明確なバリデーションによる早期リターン
public async Task<ProcessResult> ProcessPaymentAsync(
    PaymentRequest request,
    CancellationToken cancellationToken)
{
    ArgumentNullException.ThrowIfNull(request);

    if (request.Amount <= 0)
        throw new ArgumentOutOfRangeException(nameof(request.Amount), "Amount must be positive");

    if (string.IsNullOrWhiteSpace(request.Currency))
        throw new ArgumentException("Currency is required", nameof(request.Currency));

    // ハッピーパスはネストせずにここから続く
    var gateway = _gatewayFactory.Create(request.Currency);
    return await gateway.ChargeAsync(request, cancellationToken);
}
```

## 避けるべきアンチパターン

| アンチパターン                         | 修正方法                                         |
| -------------------------------------- | ------------------------------------------------ |
| `async void` メソッド                  | `Task` を返す（イベントハンドラーを除く）        |
| `.Result` または `.Wait()`             | `await` を使う                                   |
| `catch (Exception) { }`                | 処理するか、コンテキストを付けて再スローする     |
| コンストラクター内での `new Service()` | コンストラクターインジェクションを使う           |
| `public` フィールド                    | 適切なアクセサーを持つプロパティを使う           |
| ビジネスロジックでの `dynamic`         | ジェネリクスまたは明示的な型を使う               |
| ミュータブルな `static` 状態           | DI のスコープや `ConcurrentDictionary` を使う    |
| ループ内での `string.Format`           | `StringBuilder` または補間文字列ハンドラーを使う |
