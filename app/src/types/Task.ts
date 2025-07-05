export interface Task {
  id: number;
  topic: string;
  active: boolean;
  schedule: string | null;
  last_run_at: string | null;
  delivery_route: string;
  created_at: string;
  updated_at: string;
}
