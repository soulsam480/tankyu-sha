export interface TaskRun {
  id: number;
  task_id: number;
  status: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export const getTaskRuns = async (): Promise<TaskRun[]> => {
  const response = await fetch("/api/task_runs");
  return response.json();
};

export const getTaskRun = async (id: number): Promise<TaskRun> => {
  const response = await fetch(`/api/task_runs/${id}`);
  return response.json();
};

export const getTaskRunsByTaskId = async (
  taskId: string,
): Promise<TaskRun[]> => {
  const response = await fetch(`/api/task_runs/${taskId}`);
  return response.json();
};
