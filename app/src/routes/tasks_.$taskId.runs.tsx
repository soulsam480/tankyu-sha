import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { getTaskRunsByTaskId } from "../api/models/TaskRun";
import type { TaskRun } from "../api/models/TaskRun";
import { TaskRunItem } from "../components/TaskRunItem";
import { Box, Heading, Flex, Text } from "@radix-ui/themes";

const taskRunsQueryOptions = (taskId: string) => ({
  queryKey: ["tasks", taskId, "runs"],
  queryFn: () => getTaskRunsByTaskId(taskId),
});

export const Route = createFileRoute("/tasks_/$taskId/runs")({
  loader: ({ context: { queryClient }, params: { taskId } }) =>
    queryClient.ensureQueryData(taskRunsQueryOptions(taskId)),
  component: TaskRunsComponent,
});

function TaskRunsComponent() {
  const { taskId } = Route.useParams();
  const { data: taskRuns } = useQuery(taskRunsQueryOptions(taskId));

  if (!taskRuns) {
    return <Text>Loading...</Text>;
  }

  return (
    <Box p="4">
      <Heading as="h1" size="6" mb="4">
        Task Runs for Task {taskId}
      </Heading>
      <Flex direction="column" gap="2">
        {taskRuns.map((run: TaskRun) => (
          <TaskRunItem key={run.id} run={run} />
        ))}
      </Flex>
    </Box>
  );
}
