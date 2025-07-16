import { Button, Card, Flex, Switch, Text } from '@radix-ui/themes'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import type { Task } from '../api/models/Task'
import { deleteTask, updateTask } from '../api/models/Task'

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
    <Card>
      <Flex justify='between' align='center'>
        <Flex direction='column'>
          <Text weight='bold'>{task.topic}</Text>
          <Text size='1' color='gray'>
            {task.schedule}
          </Text>
        </Flex>
        <Flex align='center' gap='2'>
          <Switch
            checked={task.active}
            onCheckedChange={() => {
              updateMutation.mutate({ ...task, active: !task.active })
            }}
          />
          <Link
            to='/tasks/$taskId/runs'
            params={{ taskId: task.id.toString() }}
            style={{ color: 'var(--accent-9)' }}
          >
            View Runs
          </Link>
          <Button
            color='red'
            onClick={() => deleteMutation.mutate(task.id)}
            disabled={deleteMutation.isPending}
          >
            {deleteMutation.isPending ? 'Deleting...' : 'Delete'}
          </Button>
        </Flex>
      </Flex>
    </Card>
  )
}
