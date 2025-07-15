import { createFileRoute } from '@tanstack/react-router'
import CreateTaskFlow from '../components/CreateTaskFlow'
import LastRuns from '../components/LastRuns'

export const Route = createFileRoute('/')({
  component: StartScreen
})

function StartScreen() {
  return (
    <div className='flex p-4'>
      <div className='flex-1'>
        <CreateTaskFlow />
      </div>
      <LastRuns />
    </div>
  )
}
