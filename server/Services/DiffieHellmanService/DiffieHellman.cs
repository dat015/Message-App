using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Numerics;

namespace server.Services.DiffieHellmanService
{
    public class DiffieHellman
    {
        private readonly BigInteger p = BigInteger.Parse("23"); // Thay bằng số lớn hơn trong thực tế (2048-bit)
        private readonly BigInteger g = BigInteger.Parse("5");

        public (BigInteger p, BigInteger g) GetPublicParameters()
        {
            return (p, g);
        }

        public BigInteger GeneratePublicKey(BigInteger privateKey)
        {
            return BigInteger.ModPow(g, privateKey, p);
        }

        public BigInteger GenerateSharedKey(BigInteger otherPublicKey, BigInteger privateKey)
        {
            return BigInteger.ModPow(otherPublicKey, privateKey, p);
        }
    }
}