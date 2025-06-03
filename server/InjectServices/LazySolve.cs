using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.InjectServices
{
    public class LazyResolver<T> : Lazy<T> where T : class
    {
        public LazyResolver(IServiceProvider provider)
            : base(() => provider.GetRequiredService<T>())
        {
        }
    }

}