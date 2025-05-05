import { toast } from 'react-toastify';

interface ErrorResponse {
  message?: string;
  status?: number;
  data?: any;
}

export const handleError = (error: any) => {
  console.error('Error:', error);

  // Kiểm tra nếu là lỗi từ API response
  if (error.response) {
    const { status, data } = error.response as ErrorResponse;
    
    switch (status) {
      case 400:
        toast.error(data?.message || 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại thông tin.');
        break;
      case 401:
        toast.error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        break;
      case 403:
        toast.error('Bạn không có quyền thực hiện hành động này.');
        break;
      case 404:
        toast.error('Không tìm thấy tài nguyên yêu cầu.');
        break;
      case 409:
        toast.error('Dữ liệu đã tồn tại hoặc xung đột.');
        break;
      case 500:
        toast.error('Lỗi máy chủ. Vui lòng thử lại sau.');
        break;
      default:
        toast.error(data?.message || 'Đã xảy ra lỗi. Vui lòng thử lại sau.');
    }
  } else if (error.request) {
    // Lỗi không nhận được phản hồi từ server
    toast.error('Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.');
  } else {
    // Lỗi khác
    toast.error(error.message || 'Đã xảy ra lỗi. Vui lòng thử lại sau.');
  }
};

// Hàm xử lý lỗi cụ thể cho các chức năng
export const handleAuthError = (error: any) => {
  if (error.response?.status === 401) {
    toast.error('Email hoặc mật khẩu không chính xác.');
  } else {
    handleError(error);
  }
};

export const handleChatError = (error: any) => {
  if (error.response?.status === 404) {
    toast.error('Không tìm thấy cuộc trò chuyện.');
  } else {
    handleError(error);
  }
};

export const handleFileError = (error: any) => {
  if (error.response?.status === 413) {
    toast.error('Kích thước file quá lớn. Vui lòng chọn file nhỏ hơn.');
  } else {
    handleError(error);
  }
}; 