export interface Source {
  id: number
  url: string
  kind: string
  meta: string | null
  created_at: string
  updated_at: string
  task_id: number | null
}

export const getSources = async (): Promise<Source[]> => {
  const response = await fetch('/api/sources')
  return response.json()
}

export const getSource = async (id: number): Promise<Source> => {
  const response = await fetch(`/api/sources/${id}`)
  return response.json()
}

export const createSource = async (
  source: Omit<Source, 'id' | 'created_at' | 'updated_at'>
): Promise<Source> => {
  const response = await fetch('/api/sources', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(source)
  })
  return response.json()
}

export const updateSource = async (
  id: number,
  source: Omit<Source, 'id' | 'created_at' | 'updated_at'>
): Promise<Source> => {
  const response = await fetch(`/api/sources/${id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(source)
  })
  return response.json()
}

export const deleteSource = async (id: number): Promise<void> => {
  await fetch(`/api/sources/${id}`, {
    method: 'DELETE'
  })
}
