import { Link } from '@tanstack/react-router'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Switch } from '@headlessui/react'
import { deleteTask, updateTask } from '../api/models/Task'
import type { Task } from '../api/models/Task'

interface TaskItemProps {
  task: Task
}

export function TaskItem({ task }: TaskItemProps) {
  const queryClient = useQueryClient()

  const deleteMutation = useMutation({
    mutationFn: (id: number) => {
      return deleteTask(id)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] })
    }
  })

  const updateMutation = useMutation({
    mutationFn: (task: Task) => {
      return updateTask(task.id, task)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] })
    }
  })

  return (
    <li className='p-4 border rounded-lg flex justify-between items-center'>
      <div>
        <p className='font-semibold'>{task.topic}</p>
        <p className='text-sm text-gray-500'>{task.schedule}</p>
      </div>
      <div className='flex items-center space-x-2'>
        <Switch
          checked={task.active}
          onChange={() => {
            updateMutation.mutate({ ...task, active: !task.active })
          }}
          className={`${
            task.active ? 'bg-blue-600' : 'bg-gray-200'
          } relative inline-flex h-6 w-11 items-center rounded-full`}
        >
          <span className='sr-only'>Enable notifications</span>
          <span
            className={`${
              task.active ? 'translate-x-6' : 'translate-x-1'
            } inline-block h-4 w-4 transform rounded-full bg-white transition`}
          />
        </Switch>
        <Link
          to='/tasks/$taskId/runs'
          params={{ taskId: task.id.toString() }}
          className='text-blue-500 hover:underline'
        >
          View Runs
        </Link>
        <button
          onClick={() => deleteMutation.mutate(task.id)}
          className='bg-red-500 text-white py-1 px-3 rounded-md hover:bg-red-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500'
          disabled={deleteMutation.isPending}
        >
          {deleteMutation.isPending ? 'Deleting...' : 'Delete'}
        </button>
      </div>
    </li>
  )
}
