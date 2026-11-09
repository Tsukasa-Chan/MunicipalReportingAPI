/** Types match the ASP.NET CommunityNoticesController and SaveCommunityNoticeDTO. */
export type NoticeAudience = "All" | "Ward" | "Area";
export type NoticeCategory = "General" | "Maintenance" | "Emergency";

export interface CommunityNotice {
  id: number;
  title: string;
  description: string;
  category: NoticeCategory;
  audience: NoticeAudience;
  areaId: number | null;
  areaName: string | null;
  wardId: number | null;
  wardName: string | null;
  createdByUserId: number | null;
  createdByName: string | null;
  createdAt: string;
  updatedAt: string | null;
  expiresAt: string | null;
  isActive: boolean;
}

export type SaveCommunityNotice = Pick<CommunityNotice,
  "title" | "description" | "category" | "audience" | "areaId" | "wardId" | "expiresAt" | "isActive"
>;

export const AREAS: { id: number; name: string; wardId: number }[] = [
  {id:1,name:"Brake Village",wardId:58},{id:2,name:"Canelands",wardId:58},
  {id:3,name:"Casuarina",wardId:58},{id:4,name:"Desainagar",wardId:58},
  {id:5,name:"Ghandinagar",wardId:58},{id:6,name:"Hammonds Farm",wardId:58},
  {id:7,name:"King Shaka International Airport zone",wardId:58},{id:8,name:"La Mercy",wardId:58},
  {id:9,name:"Lungelani",wardId:58},{id:10,name:"Pholani",wardId:58},
  {id:11,name:"Sastri Circle / Belgate",wardId:58},{id:12,name:"Thuthukani",wardId:58},
  {id:13,name:"Tongaat Beach / Westbrook",wardId:58},
  {id:14,name:"Belvedere (including Belvedere North)",wardId:61},
  {id:15,name:"Buffelsdale",wardId:61},{id:16,name:"Chelmsford Heights",wardId:61},
  {id:17,name:"Emona Sunhill",wardId:61},{id:18,name:"Gwalas Farm",wardId:61},
  {id:19,name:"Mithangar",wardId:61},{id:20,name:"Plain Street",wardId:61},
  {id:21,name:"Sandfields",wardId:61},{id:22,name:"Umbhayi",wardId:61},
  {id:23,name:"Watsonia",wardId:61},
  {id:24,name:"Burbreeze",wardId:62},{id:25,name:"Fairbreeze",wardId:62},
  {id:26,name:"Flamingo Heights",wardId:62},{id:27,name:"Gandhi’s Hill",wardId:62},
  {id:28,name:"Hambanathi",wardId:62},{id:29,name:"Lauriston",wardId:62},
  {id:30,name:"Magwaveni",wardId:62},{id:31,name:"Maidstone Village",wardId:62},
  {id:32,name:"OThongathi CBD / Tongaat Central",wardId:62},
  {id:33,name:"Riverside AH",wardId:62},{id:34,name:"Tongaat Industrial / Trurolands",wardId:62},
  {id:35,name:"Vanrova",wardId:62},
];
export const WARDS = [58,61,62] as const;
