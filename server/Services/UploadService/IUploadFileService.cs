using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CloudinaryDotNet.Actions;
using server.Models;

namespace server.Services.UploadService
{
    public interface IUploadFileService
    {
        Task<Attachment> UploadFileAsync(Stream fileStream, string fileType);
    }
}