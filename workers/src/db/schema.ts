export type PlanRow = {
  code: string;
  name: string;
  quota_bytes: number;
  price_kz_month: number;
  is_active: number;
};

export type UserRow = {
  firebase_uid: string;
  email: string | null;
  display_name: string | null;
  photo_url: string | null;
  plan_code: string;
  storage_used_bytes: number;
  can_switch_api_endpoint: number;
  created_at: string;
  updated_at: string;
};

export type UserProfile = {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  plan: {
    code: string;
    name: string;
    quotaBytes: number;
    priceKzMonth: number;
    maxFileSizeBytes: number;
  };
  storageUsedBytes: number;
  storageAvailableBytes: number;
  canSwitchApiEndpoint: boolean;
  createdAt: string;
  updatedAt: string;
};
