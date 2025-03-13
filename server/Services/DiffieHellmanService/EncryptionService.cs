using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;

namespace server.Services.DiffieHellmanService
{
    public class EncryptionService
    {
        public static string Encrypt(string plainText, byte[] key)
    {
        using var aes = Aes.Create();
        aes.Key = key.Take(32).ToArray(); // AES-256 cần 32 byte
        aes.GenerateIV();
        var encryptor = aes.CreateEncryptor();
        using var ms = new MemoryStream();
        ms.Write(aes.IV, 0, aes.IV.Length); // Lưu IV vào đầu output
        using var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write);
        using var sw = new StreamWriter(cs);
        sw.Write(plainText);
        sw.Close();
        return Convert.ToBase64String(ms.ToArray());
    }

    public static string Decrypt(string cipherText, byte[] key)
    {
        var cipherBytes = Convert.FromBase64String(cipherText);
        using var aes = Aes.Create();
        aes.Key = key.Take(32).ToArray();
        var iv = cipherBytes.Take(16).ToArray(); // Lấy IV từ đầu
        aes.IV = iv;
        var decryptor = aes.CreateDecryptor();
        using var ms = new MemoryStream(cipherBytes.Skip(16).ToArray());
        using var cs = new CryptoStream(ms, decryptor, CryptoStreamMode.Read);
        using var sr = new StreamReader(cs);
        return sr.ReadToEnd();
    }
    }
}