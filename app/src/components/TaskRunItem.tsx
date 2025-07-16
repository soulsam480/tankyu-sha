import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";
import type { TaskRun } from "../api/models/TaskRun";
import { Card, Text, Flex, Box, Heading } from "@radix-ui/themes";

interface TaskRunItemProps {
  run: TaskRun;
}

export function TaskRunItem({ run }: TaskRunItemProps) {
  return (
    <Card>
      <Flex direction="column" gap="2">
        <Heading as="h3" size="3">
          Run ID: {run.id}
        </Heading>
        <Text>Status: {run.status}</Text>
        <Text>Content:</Text>
        <Box>
          <Markdown remarkPlugins={[remarkGfm]}>{run.content}</Markdown>
        </Box>
        <Text size="1" color="gray">
          {run.created_at}
        </Text>
      </Flex>
    </Card>
  );
}
