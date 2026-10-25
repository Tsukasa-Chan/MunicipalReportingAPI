using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.Data
{
    // Stable IDs: never renumber or reuse an ID, only append new Areas.
    // Ward IDs are the real ward numbers; Area IDs run 1-35 (Ward 58: 1-13, Ward 61: 14-23, Ward 62: 24-35).
    public static class LocationSeedData
    {
        public static readonly Ward[] Wards =
        {
            new Ward { Id = 58, Name = "Ward 58" },
            new Ward { Id = 61, Name = "Ward 61" },
            new Ward { Id = 62, Name = "Ward 62" },
        };

        public static readonly Area[] Areas =
        {
            new Area { Id = 1, Name = "Brake Village", WardId = 58 },
            new Area { Id = 2, Name = "Canelands", WardId = 58 },
            new Area { Id = 3, Name = "Casuarina", WardId = 58 },
            new Area { Id = 4, Name = "Desainagar", WardId = 58 },
            new Area { Id = 5, Name = "Ghandinagar", WardId = 58 },
            new Area { Id = 6, Name = "Hammonds Farm", WardId = 58 },
            new Area { Id = 7, Name = "King Shaka International Airport zone", WardId = 58 },
            new Area { Id = 8, Name = "La Mercy", WardId = 58 },
            new Area { Id = 9, Name = "Lungelani", WardId = 58 },
            new Area { Id = 10, Name = "Pholani", WardId = 58 },
            new Area { Id = 11, Name = "Sastri Circle / Belgate", WardId = 58 },
            new Area { Id = 12, Name = "Thuthukani", WardId = 58 },
            new Area { Id = 13, Name = "Tongaat Beach / Westbrook", WardId = 58 },
            new Area { Id = 14, Name = "Belvedere (including Belvedere North)", WardId = 61 },
            new Area { Id = 15, Name = "Buffelsdale", WardId = 61 },
            new Area { Id = 16, Name = "Chelmsford Heights", WardId = 61 },
            new Area { Id = 17, Name = "Emona Sunhill", WardId = 61 },
            new Area { Id = 18, Name = "Gwalas Farm", WardId = 61 },
            new Area { Id = 19, Name = "Mithangar", WardId = 61 },
            new Area { Id = 20, Name = "Plain Street", WardId = 61 },
            new Area { Id = 21, Name = "Sandfields", WardId = 61 },
            new Area { Id = 22, Name = "Umbhayi", WardId = 61 },
            new Area { Id = 23, Name = "Watsonia", WardId = 61 },
            new Area { Id = 24, Name = "Burbreeze", WardId = 62 },
            new Area { Id = 25, Name = "Fairbreeze", WardId = 62 },
            new Area { Id = 26, Name = "Flamingo Heights", WardId = 62 },
            new Area { Id = 27, Name = "Gandhi’s Hill", WardId = 62 },
            new Area { Id = 28, Name = "Hambanathi", WardId = 62 },
            new Area { Id = 29, Name = "Lauriston", WardId = 62 },
            new Area { Id = 30, Name = "Magwaveni", WardId = 62 },
            new Area { Id = 31, Name = "Maidstone Village", WardId = 62 },
            new Area { Id = 32, Name = "OThongathi CBD / Tongaat Central", WardId = 62 },
            new Area { Id = 33, Name = "Riverside AH", WardId = 62 },
            new Area { Id = 34, Name = "Tongaat Industrial / Trurolands", WardId = 62 },
            new Area { Id = 35, Name = "Vanrova", WardId = 62 },
        };
    }
}
