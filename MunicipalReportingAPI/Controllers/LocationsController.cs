using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Data;

namespace MunicipalReportingAPI.Controllers
{
    // Public (no authentication): registration needs these before the user has an account.
    [Route("api/[controller]")]
    [ApiController]
    public class LocationsController : ControllerBase
    {
        private readonly MunicipalDBContext _context;

        public LocationsController(MunicipalDBContext context)
        {
            _context = context;
        }

        [HttpGet("wards")]
        public async Task<IActionResult> GetWards()
        {
            var wards = await _context.Wards
                .OrderBy(w => w.Id)
                .Select(w => new { id = w.Id, name = w.Name })
                .ToListAsync();

            return Ok(wards);
        }

        [HttpGet("wards/{wardId:int}/areas")]
        public async Task<IActionResult> GetAreasForWard(int wardId)
        {
            if (!await _context.Wards.AnyAsync(w => w.Id == wardId))
            {
                return NotFound("Ward not found");
            }

            var areas = await _context.Areas
                .Where(a => a.WardId == wardId)
                .OrderBy(a => a.Name)
                .Select(a => new { id = a.Id, name = a.Name, wardId = a.WardId })
                .ToListAsync();

            return Ok(areas);
        }

        [HttpGet("areas/{areaId:int}")]
        public async Task<IActionResult> GetArea(int areaId)
        {
            var area = await _context.Areas
                .Where(a => a.Id == areaId)
                .Select(a => new
                {
                    id = a.Id,
                    name = a.Name,
                    wardId = a.WardId,
                    wardName = a.Ward!.Name
                })
                .FirstOrDefaultAsync();

            return area == null ? NotFound("Area not found") : Ok(area);
        }
    }
}
