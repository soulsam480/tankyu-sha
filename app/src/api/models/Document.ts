export interface Document {
  id: number;
  task_run_id: number;
  source_run_id: number;
  content_embedding: number[];
  content: string;
  created_at: string;
  updated_at: string;
  meta: string;
}
