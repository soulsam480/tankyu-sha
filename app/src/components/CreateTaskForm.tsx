import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createTask } from '../api/models/Task'
import type { Task } from '../api/models/Task'
import { useState } from 'react'

export function CreateTaskForm() {
  const queryClient = useQueryClient()
  const [topic, setTopic] = useState('')
  const [schedule, setSchedule] = useState('')
  const [deliveryRoute, setDeliveryRoute] = useState('')

  const mutation = useMutation({
    mutationFn: (
      newTask: Omit<
        Task,
        'id' | 'created_at' | 'updated_at' | 'active' | 'last_run_at'
      >
    ) => {
      return createTask(newTask)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] })
    }
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    mutation.mutate({ topic, schedule, delivery_route: deliveryRoute })
  }

  return (
    <form onSubmit={handleSubmit} className='p-4 border rounded-lg mb-4'>
      <h2 className='text-xl font-bold mb-4'>Create New Task</h2>
      <div className='space-y-4'>
        <div>
          <label
            htmlFor='topic'
            className='block text-sm font-medium text-gray-700'
          >
            Topic
          </label>
          <input
            type='text'
            id='topic'
            value={topic}
            onChange={e => setTopic(e.target.value)}
            className='mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm'
          />
        </div>
        <div>
          <label
            htmlFor='schedule'
            className='block text-sm font-medium text-gray-700'
          >
            Schedule
          </label>
          <input
            type='text'
            id='schedule'
            value={schedule}
            onChange={e => setSchedule(e.target.value)}
            className='mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm'
          />
        </div>
        <div>
          <label
            htmlFor='deliveryRoute'
            className='block text-sm font-medium text-gray-700'
          >
            Delivery Route
          </label>
          <input
            type='text'
            id='deliveryRoute'
            value={deliveryRoute}
            onChange={e => setDeliveryRoute(e.target.value)}
            className='mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm'
          />
        </div>
      </div>
      <button
        type='submit'
        className='mt-4 w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500'
        disabled={mutation.isPending}
      >
        {mutation.isPending ? 'Creating...' : 'Create Task'}
      </button>
      {mutation.isError && (
        <p className='mt-2 text-sm text-red-600'>
          Error: {mutation.error.message}
        </p>
      )}
    </form>
  )
}
