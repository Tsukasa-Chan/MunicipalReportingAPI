import type { IssueRecord, PortalState, PortalUser, Report } from "@/Models/municipal";

const DEMO_PASSWORD = "Password123!";

export const DEMO_ACCOUNTS = {
  admin: { email: "admin@municore.gov", password: DEMO_PASSWORD },
  supervisor: { email: "c.thorne@municore.gov", password: DEMO_PASSWORD },
};

const users: PortalUser[] = [
  { id: "usr-1", fullName: "Director Elena Vance", email: "admin@municore.gov", phone: "+1 (555) 400-1000", ward: "All Jurisdictions", role: "Admin", registeredDate: "2026-01-05", password: DEMO_PASSWORD },
  { id: "usr-2", fullName: "Officer C. Thorne", email: "c.thorne@municore.gov", phone: "+1 (555) 400-1101", ward: "Ward 2 - Central", role: "Supervisor", registeredDate: "2026-01-12", password: DEMO_PASSWORD },
  { id: "usr-3", fullName: "Chief Mateo Torres", email: "m.torres@municore.gov", phone: "+1 (555) 400-1102", ward: "Ward 4 - Northside", role: "Supervisor", registeredDate: "2026-01-12", password: DEMO_PASSWORD },
  { id: "usr-4", fullName: "Foreman Nadia Petrov", email: "n.petrov@municore.gov", phone: "+1 (555) 400-1103", ward: "Ward 1 - Downtown", role: "Supervisor", registeredDate: "2026-02-03", password: DEMO_PASSWORD },
  { id: "usr-5", fullName: "Marcus Vance", email: "marcus.vance@example.com", phone: "+1 (555) 349-8812", ward: "Ward 4 - Northside", role: "Resident", registeredDate: "2026-02-14", password: DEMO_PASSWORD },
  { id: "usr-6", fullName: "Elena Rostova", email: "elena.r@example.com", phone: "+1 (555) 891-2309", ward: "Ward 2 - Central", role: "Resident", registeredDate: "2026-03-08", password: DEMO_PASSWORD },
  { id: "usr-7", fullName: "David Kim", email: "d.kim@citynet.org", phone: "+1 (555) 431-7762", ward: "Ward 6 - West End", role: "Resident", registeredDate: "2026-03-22", password: DEMO_PASSWORD },
  { id: "usr-8", fullName: "Amina Al-Sayed", email: "amina.sayed@urbanpost.com", phone: "+1 (555) 762-9011", ward: "Ward 1 - Downtown", role: "Resident", registeredDate: "2026-04-02", password: DEMO_PASSWORD },
  { id: "usr-9", fullName: "Carlos Mendoza", email: "c.mendoza@example.com", phone: "+1 (555) 219-4458", ward: "Ward 3 - East District", role: "Resident", registeredDate: "2026-04-19", password: DEMO_PASSWORD },
  { id: "usr-10", fullName: "Rachel Green", email: "rachel.green@example.com", phone: "+1 (555) 674-1234", ward: "Ward 5 - South Ridge", role: "Resident", registeredDate: "2026-05-01", password: DEMO_PASSWORD },
];

const IMG = "https://wpvc-images.s3.us-east-1.amazonaws.com/images/1807143/img/";

interface SeedReport { resident: string; at: string; text: string; photo?: string }
interface SeedIssue { issue: IssueRecord; reports: SeedReport[] }

const seeds: SeedIssue[] = [
  {
    issue: { id: "iss-1", issueNumber: "ISS-0001", category: "Water & Sanitation", issueType: "Burst pipe", location: "North 5th Ave & Elm St", latitude: 34.0537, longitude: -118.2427, status: "In Progress", supervisorId: "usr-3", createdAt: "2026-09-28T08:30:00Z", updatedAt: "2026-09-29T07:10:00Z" },
    reports: [
      { resident: "usr-5", at: "2026-09-28T08:30:00Z", text: "Water is gushing out of the road at the corner and flooding the intersection.", photo: IMG + "burst_pipe_inspection.png" },
      { resident: "usr-6", at: "2026-09-28T09:05:00Z", text: "Pressure at home dropped to a trickle. Looks like the main line on Elm St has burst." },
      { resident: "usr-7", at: "2026-09-28T10:40:00Z", text: "The road surface is starting to cave in where the water is running." },
      { resident: "usr-10", at: "2026-09-28T13:15:00Z", text: "Still leaking this afternoon, the whole block is without water." },
    ],
  },
  {
    issue: { id: "iss-2", issueNumber: "ISS-0002", category: "Roads & Stormwater", issueType: "Pothole", location: "Central Blvd, eastbound lane", latitude: 34.0522, longitude: -118.2437, status: "Reported", supervisorId: null, createdAt: "2026-09-30T09:15:00Z", updatedAt: null },
    reports: [
      { resident: "usr-6", at: "2026-09-30T09:15:00Z", text: "Deep pothole, rebar is showing. Damaged my wheel rim this morning.", photo: IMG + "pothole_asphalt_hazard.png" },
      { resident: "usr-8", at: "2026-09-30T11:20:00Z", text: "It keeps getting bigger after the rain. Cars are swerving into the next lane." },
      { resident: "usr-9", at: "2026-10-01T07:45:00Z", text: "Someone is going to get hurt here, please fix it soon." },
      { resident: "usr-5", at: "2026-10-01T18:30:00Z", text: "Hit it last night, burst a tyre." },
      { resident: "usr-7", at: "2026-10-02T08:05:00Z", text: "Same pothole on Central Blvd, now about half a metre wide." },
    ],
  },
  {
    issue: { id: "iss-3", issueNumber: "ISS-0003", category: "Electricity", issueType: "Street light not working", location: "Elm Corridor, near the elementary school", latitude: 34.0489, longitude: -118.258, status: "In Progress", supervisorId: "usr-2", createdAt: "2026-09-25T21:40:00Z", updatedAt: "2026-09-27T08:00:00Z" },
    reports: [
      { resident: "usr-7", at: "2026-09-25T21:40:00Z", text: "Whole row of four lights is flickering and then going out near the school path.", photo: IMG + "streetlight_repair_inspection.png" },
      { resident: "usr-6", at: "2026-09-26T19:10:00Z", text: "Completely dark on Elm Corridor at night. Not safe for kids walking home." },
      { resident: "usr-10", at: "2026-09-26T21:50:00Z", text: "Heard buzzing from the transformer box next to the lights." },
    ],
  },
  {
    issue: { id: "iss-4", issueNumber: "ISS-0004", category: "Waste Management", issueType: "Illegal dumping", location: "Alley behind 14 Market St", latitude: 34.056, longitude: -118.239, status: "Fixed", supervisorId: "usr-4", createdAt: "2026-09-20T14:05:00Z", updatedAt: "2026-09-22T17:30:00Z" },
    reports: [
      { resident: "usr-8", at: "2026-09-20T14:05:00Z", text: "Pallets and household rubbish dumped in the alley, blocking access.", photo: IMG + "waste_overflow_site.png" },
      { resident: "usr-9", at: "2026-09-21T08:20:00Z", text: "The pile has grown over the weekend, rats are starting to show up." },
    ],
  },
  {
    issue: { id: "iss-5", issueNumber: "ISS-0005", category: "Roads & Stormwater", issueType: "Traffic light not working", location: "Main St & 3rd Ave", latitude: 34.0498, longitude: -118.232, status: "Reported", supervisorId: "usr-2", createdAt: "2026-10-01T11:20:00Z", updatedAt: "2026-10-01T15:00:00Z" },
    reports: [
      { resident: "usr-9", at: "2026-10-01T11:20:00Z", text: "Pedestrian signal knocked over by a car, the countdown button is dead.", photo: IMG + "traffic_light_damage.png" },
      { resident: "usr-8", at: "2026-10-01T12:00:00Z", text: "Lights at Main & 3rd are black, drivers are not stopping." },
      { resident: "usr-5", at: "2026-10-01T12:40:00Z", text: "Near miss with a cyclist here just now. Signals are out." },
      { resident: "usr-6", at: "2026-10-01T16:25:00Z", text: "Still out this evening, rush hour is chaos." },
      { resident: "usr-7", at: "2026-10-02T07:30:00Z", text: "No power to the signal this morning either." },
      { resident: "usr-10", at: "2026-10-02T09:10:00Z", text: "A police officer is directing traffic but the lights are still dead." },
    ],
  },
  {
    issue: { id: "iss-6", issueNumber: "ISS-0006", category: "Roads & Stormwater", issueType: "Blocked storm drain", location: "Ridge Rd bike lane", latitude: 34.041, longitude: -118.249, status: "Fixed", supervisorId: "usr-3", createdAt: "2026-09-18T16:50:00Z", updatedAt: "2026-09-19T19:15:00Z" },
    reports: [
      { resident: "usr-10", at: "2026-09-18T16:50:00Z", text: "Branches and silt are plugging the drain, a deep puddle is covering the bike lane.", photo: IMG + "storm_drain_culvert.png" },
      { resident: "usr-9", at: "2026-09-18T18:30:00Z", text: "Water is backing up onto the road at Ridge Rd." },
    ],
  },
  {
    issue: { id: "iss-7", issueNumber: "ISS-0007", category: "Water & Sanitation", issueType: "Sewage spill", location: "West End Park entrance", latitude: 34.0471, longitude: -118.2612, status: "Reported", supervisorId: null, createdAt: "2026-10-02T06:55:00Z", updatedAt: null },
    reports: [
      { resident: "usr-7", at: "2026-10-02T06:55:00Z", text: "Sewage is coming up through the manhole at the park gate. Terrible smell." },
    ],
  },
  {
    issue: { id: "iss-8", issueNumber: "ISS-0008", category: "Electricity", issueType: "Exposed or damaged cable", location: "Harbour Rd substation fence", latitude: 34.0455, longitude: -118.2385, status: "Reported", supervisorId: null, createdAt: "2026-10-02T10:10:00Z", updatedAt: null },
    reports: [
      { resident: "usr-9", at: "2026-10-02T10:10:00Z", text: "A cable is hanging out of the fence and touching the pavement. Children walk past here." },
      { resident: "usr-8", at: "2026-10-02T12:45:00Z", text: "Saw sparks from the exposed wire near the substation." },
    ],
  },
  {
    issue: { id: "iss-9", issueNumber: "ISS-0009", category: "Waste Management", issueType: "Overflowing public bin", location: "Downtown Plaza", latitude: 34.0553, longitude: -118.2461, status: "In Progress", supervisorId: "usr-4", createdAt: "2026-09-29T12:00:00Z", updatedAt: "2026-10-01T08:30:00Z" },
    reports: [
      { resident: "usr-8", at: "2026-09-29T12:00:00Z", text: "All the bins around the plaza are overflowing after the weekend market." },
      { resident: "usr-5", at: "2026-09-30T08:10:00Z", text: "Rubbish is blowing across the plaza and into the street." },
      { resident: "usr-6", at: "2026-09-30T17:35:00Z", text: "Bins still not emptied. Smells bad in the heat." },
    ],
  },
];

/** Build a fresh copy of the demo data set. */
export function buildSeed(): PortalState {
  const residentName = new Map(users.map((u) => [u.id, u.fullName] as const));
  const reports: Report[] = [];

  for (const { issue, reports: items } of seeds) {
    for (const item of items) {
      reports.push({
        id: `rep-${reports.length + 1}`,
        issueId: issue.id,
        residentId: item.resident,
        residentName: residentName.get(item.resident) ?? "Unknown resident",
        description: item.text,
        photoUrl: item.photo ?? "",
        location: issue.location,
        submittedAt: item.at,
      });
    }
  }

  return {
    version: 1,
    users: users.map((u) => ({ ...u })),
    issues: seeds.map((s) => ({ ...s.issue })),
    reports,
  };
}
