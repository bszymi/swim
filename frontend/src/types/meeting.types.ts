export interface Meeting {
  id: number;
  name: string;
  season: string;
  region?: string;
  promoter?: string;
  pool_required: 'LC' | 'SC';
  age_rule_type: string;
  age_rule_date?: string;
  window_start: string;
  window_end: string;
  created_at?: string;
  updated_at?: string;
}

export interface MeetingWithStandards extends Meeting {
  meeting_standards: MeetingStandard[];
}

export interface MeetingStandard {
  id: number;
  meeting_id: number;
  stroke: string;
  distance_m: number;
  pool_of_standard: 'LC' | 'SC';
  standard_type: 'QUALIFY' | 'CONSIDER';
  time_seconds: number;
  age_min: number;
  age_max: number;
  gender: 'M' | 'F';
}

export interface ParsedMeetDatum {
  id: number;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  error_message?: string;
  data?: {
    meet_name?: string;
    season?: string;
    pool_required?: string;
    window_start?: string;
    window_end?: string;
    age_calculation?: {
      method?: string;
      date?: string;
    };
    standards?: Array<{
      stroke: string;
      distance_m: number;
      course_type: string;
      age_group?: string;
      sex: string;
      qualifying_time: string;
    }>;
  };
}
