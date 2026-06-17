---
name: csharp-testing
description: C# and .NET testing patterns with xUnit, FluentAssertions, mocking, integration tests, and test organization best practices.
---

# C# テストパターン

xUnit、FluentAssertions、そしてモダンなテスト手法を用いた .NET アプリケーション向けの包括的なテストパターンです。

## 有効化のタイミング

- C# コードに新しいテストを書くとき
- テストの品質とカバレッジをレビューするとき
- .NET プロジェクトのテストインフラを構築するとき
- フレーキー（不安定）なテストや遅いテストをデバッグするとき

## テストフレームワークのスタック

| ツール                         | 用途                                |
| ------------------------------ | ----------------------------------- |
| **xUnit**                      | テストフレームワーク（.NET で推奨） |
| **FluentAssertions**           | 読みやすいアサーション構文          |
| **NSubstitute** または **Moq** | 依存関係のモック化                  |
| **Testcontainers**             | 結合テストでの実インフラ            |
| **WebApplicationFactory**      | ASP.NET Core の結合テスト           |
| **Bogus**                      | 現実的なテストデータの生成          |

## ユニットテストの構造

### Arrange-Act-Assert

```csharp
public sealed class OrderServiceTests
{
    private readonly IOrderRepository _repository = Substitute.For<IOrderRepository>();
    private readonly ILogger<OrderService> _logger = Substitute.For<ILogger<OrderService>>();
    private readonly OrderService _sut;

    public OrderServiceTests()
    {
        _sut = new OrderService(_repository, _logger);
    }

    [Fact]
    public async Task PlaceOrderAsync_ReturnsSuccess_WhenRequestIsValid()
    {
        // 準備 (Arrange)
        var request = new CreateOrderRequest
        {
            CustomerId = "cust-123",
            Items = [new OrderItem("SKU-001", 2, 29.99m)]
        };

        // 実行 (Act)
        var result = await _sut.PlaceOrderAsync(request, CancellationToken.None);

        // 検証 (Assert)
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().NotBeNull();
        result.Value!.CustomerId.Should().Be("cust-123");
    }

    [Fact]
    public async Task PlaceOrderAsync_ReturnsFailure_WhenNoItems()
    {
        // 準備 (Arrange)
        var request = new CreateOrderRequest
        {
            CustomerId = "cust-123",
            Items = []
        };

        // 実行 (Act)
        var result = await _sut.PlaceOrderAsync(request, CancellationToken.None);

        // 検証 (Assert)
        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Contain("at least one item");
    }
}
```

### Theory によるパラメータ化テスト

```csharp
[Theory]
[InlineData("", false)]
[InlineData("a", false)]
[InlineData("ab@c.d", false)]
[InlineData("user@example.com", true)]
[InlineData("user+tag@example.co.uk", true)]
public void IsValidEmail_ReturnsExpected(string email, bool expected)
{
    EmailValidator.IsValid(email).Should().Be(expected);
}

[Theory]
[MemberData(nameof(InvalidOrderCases))]
public async Task PlaceOrderAsync_RejectsInvalidOrders(CreateOrderRequest request, string expectedError)
{
    var result = await _sut.PlaceOrderAsync(request, CancellationToken.None);

    result.IsSuccess.Should().BeFalse();
    result.Error.Should().Contain(expectedError);
}

public static TheoryData<CreateOrderRequest, string> InvalidOrderCases => new()
{
    { new() { CustomerId = "", Items = [ValidItem()] }, "CustomerId" },
    { new() { CustomerId = "c1", Items = [] }, "at least one item" },
    { new() { CustomerId = "c1", Items = [new("", 1, 10m)] }, "SKU" },
};
```

## NSubstitute によるモック化

```csharp
[Fact]
public async Task GetOrderAsync_ReturnsNull_WhenNotFound()
{
    // 準備 (Arrange)
    var orderId = Guid.NewGuid();
    _repository.FindByIdAsync(orderId, Arg.Any<CancellationToken>())
        .Returns((Order?)null);

    // 実行 (Act)
    var result = await _sut.GetOrderAsync(orderId, CancellationToken.None);

    // 検証 (Assert)
    result.Should().BeNull();
}

[Fact]
public async Task PlaceOrderAsync_PersistsOrder()
{
    // 準備 (Arrange)
    var request = ValidOrderRequest();

    // 実行 (Act)
    await _sut.PlaceOrderAsync(request, CancellationToken.None);

    // 検証 — リポジトリが呼ばれたことを確認
    await _repository.Received(1).AddAsync(
        Arg.Is<Order>(o => o.CustomerId == request.CustomerId),
        Arg.Any<CancellationToken>());
}
```

## ASP.NET Core の結合テスト

### WebApplicationFactory のセットアップ

```csharp
public sealed class OrderApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public OrderApiTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // テスト用に実 DB をインメモリ DB に置き換える
                services.RemoveAll<DbContextOptions<AppDbContext>>();
                services.AddDbContext<AppDbContext>(options =>
                    options.UseInMemoryDatabase("TestDb"));
            });
        }).CreateClient();
    }

    [Fact]
    public async Task GetOrder_Returns404_WhenNotFound()
    {
        var response = await _client.GetAsync($"/api/orders/{Guid.NewGuid()}");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task CreateOrder_Returns201_WithValidRequest()
    {
        var request = new CreateOrderRequest
        {
            CustomerId = "cust-1",
            Items = [new("SKU-001", 1, 19.99m)]
        };

        var response = await _client.PostAsJsonAsync("/api/orders", request);

        response.StatusCode.Should().Be(HttpStatusCode.Created);
        response.Headers.Location.Should().NotBeNull();
    }
}
```

### Testcontainers を使ったテスト

```csharp
public sealed class PostgresOrderRepositoryTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder()
        .WithImage("postgres:16-alpine")
        .Build();

    private AppDbContext _db = null!;

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(_postgres.GetConnectionString())
            .Options;
        _db = new AppDbContext(options);
        await _db.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        await _db.DisposeAsync();
        await _postgres.DisposeAsync();
    }

    [Fact]
    public async Task AddAsync_PersistsOrder()
    {
        var repo = new SqlOrderRepository(_db);
        var order = Order.Create("cust-1", [new OrderItem("SKU-001", 2, 10m)]);

        await repo.AddAsync(order, CancellationToken.None);

        var found = await repo.FindByIdAsync(order.Id, CancellationToken.None);
        found.Should().NotBeNull();
        found!.Items.Should().HaveCount(1);
    }
}
```

## テストの構成

```
tests/
  MyApp.UnitTests/
    Services/
      OrderServiceTests.cs
      PaymentServiceTests.cs
    Validators/
      EmailValidatorTests.cs
  MyApp.IntegrationTests/
    Api/
      OrderApiTests.cs
    Repositories/
      OrderRepositoryTests.cs
  MyApp.TestHelpers/
    Builders/
      OrderBuilder.cs
    Fixtures/
      DatabaseFixture.cs
```

## テストデータビルダー

```csharp
public sealed class OrderBuilder
{
    private string _customerId = "cust-default";
    private readonly List<OrderItem> _items = [new("SKU-001", 1, 10m)];

    public OrderBuilder WithCustomer(string customerId)
    {
        _customerId = customerId;
        return this;
    }

    public OrderBuilder WithItem(string sku, int quantity, decimal price)
    {
        _items.Add(new OrderItem(sku, quantity, price));
        return this;
    }

    public Order Build() => Order.Create(_customerId, _items);
}

// テストでの使用例
var order = new OrderBuilder()
    .WithCustomer("cust-vip")
    .WithItem("SKU-PREMIUM", 3, 99.99m)
    .Build();
```

## よくあるアンチパターン

| アンチパターン                          | 修正方法                                                                       |
| --------------------------------------- | ------------------------------------------------------------------------------ |
| 実装の詳細をテストする                  | 振る舞いと結果をテストする                                                     |
| 共有された可変なテスト状態              | テストごとに新しいインスタンスを使う（xUnit はコンストラクタでこれを実現する） |
| 非同期テストでの `Thread.Sleep`         | タイムアウト付きの `Task.Delay`、またはポーリングヘルパーを使う                |
| `ToString()` の出力に対するアサーション | 型付きのプロパティに対してアサーションする                                     |
| 1 つのテストに巨大なアサーションが 1 つ | 1 つのテストに論理的なアサーションを 1 つ                                      |
| 実装を表すテスト名                      | 振る舞いで命名する: `Method_ExpectedResult_WhenCondition`                      |
| `CancellationToken` を無視する          | 常に渡し、キャンセルを検証する                                                 |

## テストの実行

```bash
# すべてのテストを実行する
dotnet test

# カバレッジ付きで実行する
dotnet test --collect:"XPlat Code Coverage"

# 特定のプロジェクトを実行する
dotnet test tests/MyApp.UnitTests/

# テスト名でフィルタする
dotnet test --filter "FullyQualifiedName~OrderService"

# 開発中のウォッチモード
dotnet watch test --project tests/MyApp.UnitTests/
```
