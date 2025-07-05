export interface SourceRun {
  id: number
  status: string
  content: string | null
  summary: string | null
  created_at: string
  updated_at: string
  source_id: number
  task_run_id: number | null
}

export const getSourceRuns = async (): Promise<SourceRun[]> => {
  const response = await fetch('/api/source_runs')
  return response.json()
}

export const getSourceRun = async (id: number): Promise<SourceRun> => {
  const response = await fetch(`/api/source_runs/${id}`)
  return response.json()
}
