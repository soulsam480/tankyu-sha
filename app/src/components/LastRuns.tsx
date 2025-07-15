import { useQuery } from '@tanstack/react-query'
import { getTaskRuns } from '@/api/models/TaskRun'
import { TaskRunItem } from './TaskRunItem'

export default function LastRuns() {
  const { data: taskRuns = [] } = useQuery({
    queryKey: ['taskRuns'],
    queryFn: getTaskRuns
  })

  return (
    <div className='w-1/3 p-4 border-l'>
      <h2 className='text-xl font-bold mb-4'>Last runs</h2>
      <div className='space-y-2'>
        {taskRuns.map(run => (
          <TaskRunItem key={run.id} run={run} />
        ))}
      </div>
    </div>
  )
}
