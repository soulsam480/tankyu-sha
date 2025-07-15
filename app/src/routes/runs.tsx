import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/runs')({
  component: () => <div>Runs</div>
})
