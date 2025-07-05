import { createFileRoute } from '@tanstack/react-router'
import { useQuery } from '@tanstack/react-query'
import { getTaskRunsByTaskId } from '../api/models/TaskRun'
import type { TaskRun } from '../api/models/TaskRun'
import { TaskRunItem } from '../components/TaskRunItem'

const taskRunsQueryOptions = (taskId: string) => ({
  queryKey: ['tasks', taskId, 'runs'],
  queryFn: () => getTaskRunsByTaskId(taskId)
})

export const Route = createFileRoute('/tasks_/$taskId/runs')({
  loader: ({ context: { queryClient }, params: { taskId } }) =>
    queryClient.ensureQueryData(taskRunsQueryOptions(taskId)),
  component: TaskRunsComponent
})

function TaskRunsComponent() {
  const { taskId } = Route.useParams()
  const { data: taskRuns } = useQuery(taskRunsQueryOptions(taskId))

  if (!taskRuns) {
    return <div>Loading...</div>
  }

  return (
    <div className='p-4'>
      <h1 className='text-2xl font-bold mb-4'>Task Runs for Task {taskId}</h1>
      <ul className='space-y-2'>
        {taskRuns.map((run: TaskRun) => (
          <TaskRunItem key={run.id} run={run} />
        ))}
      </ul>
    </div>
  )
}
