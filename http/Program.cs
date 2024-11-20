using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices((context, services) =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = context.Configuration.GetConnectionString("RedisConnection");
            options.InstanceName = "contentapiCache";
        });
    })
    .Build();

host.Run();
