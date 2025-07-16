import { useQuery } from "@tanstack/react-query";
import { getTaskRuns } from "@/api/models/TaskRun";
import { TaskRunItem } from "./TaskRunItem";
import { Card, Heading, Inset, Flex, Box } from "@radix-ui/themes";

export default function LastRuns() {
  const { data: taskRuns = [] } = useQuery({
    queryKey: ["taskRuns"],
    queryFn: getTaskRuns,
  });

  return (
    <Card>
      <Inset>
        <Box p="4">
          <Heading as="h2" size="4">
            Last runs
          </Heading>
        </Box>
      </Inset>
      <Flex direction="column" gap="2" p="4">
        {taskRuns.map((run) => (
          <TaskRunItem key={run.id} run={run} />
        ))}
      </Flex>
    </Card>
  );
}
