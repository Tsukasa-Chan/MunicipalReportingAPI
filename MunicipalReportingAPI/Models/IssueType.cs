namespace MunicipalReportingAPI.Models
{
    public enum IssueType
    {
        // water and sanitation
        BurstPipe,
        LeakingPipe,
        NoWaterSupply,
        LowWaterPressure,
        BlockedSewerOrManhole,
        SewageSpill,
        DiscoloredOrDirtyWater,

        // Roads and Stormwater
       Pothole,
       Sinkhole,
       BlockedStormDrain,
       FloodedRoad,
       TrafficLightNotWorking,
       MissingOrDamagedRoadSign,
       FadedRoadMarkings,

        // Electricity
        StreetLightNotWorking,
        StreetLightOnDuringDay,
        PowerOutage,
        ExposedOrDamagedCable,
        DamagedElectricalBox,


        // Waste Management
        MissedBinCollection,
        IllegalDumping,
        OverflowingPublicBin,
    }
}
