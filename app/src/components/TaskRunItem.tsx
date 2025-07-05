import type { TaskRun } from '../api/models/TaskRun'

interface TaskRunItemProps {
  run: TaskRun
}

export function TaskRunItem({ run }: TaskRunItemProps) {
  return (
    <li className='p-4 border rounded-lg'>
      <p className='font-semibold'>Run ID: {run.id}</p>
      <p>Status: {run.status}</p>
      <p>Content: {run.content}</p>
      <p className='text-sm text-gray-500'>Created at: {run.created_at}</p>
    </li>
  )
}
