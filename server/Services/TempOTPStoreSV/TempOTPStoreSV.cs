using System;
using System.Collections.Concurrent;
using System.Linq;
using System.Timers;

namespace server.Services.TempOTPStoreSV
{
    public class TempOTPStore
    {
        private readonly ConcurrentDictionary<string, List<TempOTPModel>> _otpStorage = new();
        private readonly System.Timers.Timer _cleanupTimer;

        public TempOTPStore()
        {
            Console.WriteLine($"TempOTPStore instance created: {GetHashCode()}");

            // Khởi tạo và cài đặt Timer để chạy mỗi 1 phút
            _cleanupTimer = new System.Timers.Timer(60000); // 60000ms = 1 phút
            _cleanupTimer.Elapsed += CleanupExpiredOrUsedOTPs;
            _cleanupTimer.Start();
        }

        // Lưu OTP
        public void SaveOTP(string email, string otpCode, int expiryMinutes = 5)
        {
            var otpModel = new TempOTPModel
            {
                Email = email,
                OTPCode = otpCode,
                CreatedDate = DateTime.UtcNow,
                ExpiryDate = DateTime.UtcNow.AddMinutes(expiryMinutes),
                IsUsed = false
            };

            _otpStorage.AddOrUpdate(
                email,
                new List<TempOTPModel> { otpModel },
                (key, oldList) =>
                {
                    oldList.Add(otpModel);
                    return oldList;
                });
            Console.WriteLine($"Saved OTP {otpCode} for email {email}, expires at {otpModel.ExpiryDate}");
            LogStorageState();
        }

        // Lấy OTP hợp lệ mới nhất
        public TempOTPModel GetLatestValidOTP(string email)
        {
            LogStorageState();
            if (_otpStorage.TryGetValue(email, out var otpList))
            {
                var validOTP = otpList
                    .Where(o => o.ExpiryDate > DateTime.UtcNow && !o.IsUsed) // Chỉ lấy OTP chưa hết hạn và chưa sử dụng
                    .OrderByDescending(o => o.CreatedDate)
                    .FirstOrDefault();
                if (validOTP == null)
                {
                    Console.WriteLine($"No valid OTP found for email {email}. Total OTPs: {otpList.Count}");
                }
                else
                {
                    Console.WriteLine($"Found valid OTP {validOTP.OTPCode} for email {email}, expires at {validOTP.ExpiryDate}");
                }
                return validOTP;
            }
            Console.WriteLine($"No OTP list found for email {email}");
            return null;
        }

        // Đánh dấu OTP đã sử dụng
        public void MarkOTPAsUsed(string email, string otpCode)
        {
            if (_otpStorage.TryGetValue(email, out var otpList))
            {
                var otp = otpList.FirstOrDefault(o => o.OTPCode == otpCode && !o.IsUsed);
                if (otp != null)
                {
                    otp.IsUsed = true;
                    Console.WriteLine($"Marked OTP {otpCode} as used for email {email}");
                }
                else
                {
                    Console.WriteLine($"Could not find OTP {otpCode} to mark as used for email {email}");
                }
            }
        }

        // Dọn dẹp các OTP hết hạn hoặc đã sử dụng
        private void CleanupExpiredOrUsedOTPs(object sender, ElapsedEventArgs e)
        {
            foreach (var pair in _otpStorage)
            {
                pair.Value.RemoveAll(o => o.ExpiryDate <= DateTime.UtcNow || o.IsUsed);
            }
            LogStorageState();
        }

        // In trạng thái của OTP
        public void LogStorageState()
        {
            Console.WriteLine($"_otpStorage contains {_otpStorage.Count} emails.");
            foreach (var pair in _otpStorage)
            {
                Console.WriteLine($"Email: {pair.Key}, OTPs: {pair.Value.Count}, Details: {string.Join(", ", pair.Value.Select(o => $"Code={o.OTPCode}, Expires={o.ExpiryDate}, Used={o.IsUsed}"))}");
            }
        }
    }

    // Mô hình OTP
    public class TempOTPModel
    {
        public string Email { get; set; }
        public string OTPCode { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime ExpiryDate { get; set; }
        public bool IsUsed { get; set; }
    }
}
