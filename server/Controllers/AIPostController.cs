using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.Services;

[ApiController]
[Route("api/[controller]")]
public class AIPostController : ControllerBase
{
    private readonly IAIPostSV _aiPostSV;

    public AIPostController(IAIPostSV aiPostSV)
    {
        _aiPostSV = aiPostSV;
    }

    [HttpPost("generate-custom")]
    public async Task<IActionResult> GenerateFromPrompt([FromBody] CustomPromptRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Prompt))
        {
            return BadRequest("Prompt không được để trống hoặc không hợp lệ.");
        }

        try
        {
            var result = await _aiPostSV.GenerateFromPromptAsync(request.Prompt);
            return Ok(new { result });
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.ToString());
            return StatusCode(500, "Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại sau.");
        }
    }
}