import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { getTasks } from "../api/models/Task";
import type { Task } from "../api/models/Task";
import { Box, Heading, Flex } from "@radix-ui/themes";

const tasksQueryOptions = {
  queryKey: ["tasks"],
  queryFn: getTasks,
};

export const Route = createFileRoute("/tasks")({
  loader: ({ context: { queryClient } }) =>
    queryClient.ensureQueryData(tasksQueryOptions),
  component: TasksComponent,
});

import { CreateTaskForm } from "../components/CreateTaskForm";

import { TaskItem } from "../components/TaskItem";

function TasksComponent() {
  const { data: tasks } = useQuery(tasksQueryOptions);

  return (
    <Box p="4">
      <Heading as="h1" size="6" mb="4">
        Tasks
      </Heading>
      <CreateTaskForm />
      <Flex direction="column" gap="2">
        {tasks?.map((task: Task) => (
          <TaskItem key={task.id} task={task} />
        ))}
      </Flex>
    </Box>
  );
}
