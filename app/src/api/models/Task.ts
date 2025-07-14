export interface Task {
  id: number
  topic: string
  active: boolean
  schedule: string | null
  last_run_at: string | null
  delivery_route: string
  created_at: string
  updated_at: string
}

export const getTasks = async (): Promise<Task[]> => {
  const response = await fetch('/api/tasks')
  return response.json()
}

export const getTask = async (id: number): Promise<Task> => {
  const response = await fetch(`/api/tasks/${id}`)
  return response.json()
}

export const createTask = async (
  task: Omit<
    Task,
    'id' | 'created_at' | 'updated_at' | 'active' | 'last_run_at'
  >
): Promise<Task> => {
  const response = await fetch('/api/tasks', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(task)
  })
  return response.json()
}

export const updateTask = async (
  id: number,
  task: Omit<Task, 'id' | 'created_at' | 'updated_at' | 'last_run_at'>
): Promise<Task> => {
  const response = await fetch(`/api/tasks/${id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(task)
  })
  return response.json()
}

export const deleteTask = async (id: number): Promise<void> => {
  await fetch(`/api/tasks/${id}`, {
    method: 'DELETE'
  })
}
