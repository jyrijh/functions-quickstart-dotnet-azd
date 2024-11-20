using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;

namespace Company.Function
{
    public class httpGetFunction
    {
        private readonly ILogger _logger;
        private readonly IDistributedCache _cache;

        public httpGetFunction(ILoggerFactory loggerFactory, IDistributedCache cache)
        {
            _logger = loggerFactory.CreateLogger<httpGetFunction>();
            _cache = cache;
        }

        [Function("httpget")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get")]
          HttpRequest req,
          string name = "World")
        {
            try {
                if(await _cache.GetStringAsync(name) is string cachedValue)
                {
                    _logger.LogInformation($"C# HTTP trigger function processed a request for {cachedValue} from cache.");
                    return new OkObjectResult(cachedValue);
                }

                var returnValue = string.IsNullOrEmpty(name)
                    ? "Hello, World."
                    : $"Hello, {name}.";

                await _cache.SetStringAsync(name, returnValue);
    
                _logger.LogInformation($"C# HTTP trigger function processed a request for {returnValue}.");
    
                return new OkObjectResult(returnValue);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred in the function.");
                return new StatusCodeResult(StatusCodes.Status500InternalServerError);
            }
        }
    }

}