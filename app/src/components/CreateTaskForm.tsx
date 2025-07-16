import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createTask } from "../api/models/Task";
import type { Task } from "../api/models/Task";
import { useState } from "react";
import {
  Card,
  Heading,
  Flex,
  TextField,
  Button,
  Text,
  Box,
} from "@radix-ui/themes";

export function CreateTaskForm() {
  const queryClient = useQueryClient();
  const [topic, setTopic] = useState("");
  const [schedule, setSchedule] = useState("");
  const [deliveryRoute, setDeliveryRoute] = useState("");

  const mutation = useMutation({
    mutationFn: (
      newTask: Omit<
        Task,
        "id" | "created_at" | "updated_at" | "active" | "last_run_at"
      >,
    ) => {
      return createTask(newTask);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate({ topic, schedule, delivery_route: deliveryRoute });
  };

  return (
    <Card mb="4">
      <form onSubmit={handleSubmit}>
        <Heading as="h2" size="4" mb="4">
          Create New Task
        </Heading>
        <Flex direction="column" gap="4">
          <Box>
            <Text as="label" size="2" mb="1" weight="bold">
              Topic
            </Text>
            <TextField.Root
              type="text"
              id="topic"
              value={topic}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                setTopic(e.target.value)
              }
              size="2"
            />
          </Box>
          <Box>
            <Text as="label" size="2" mb="1" weight="bold">
              Schedule
            </Text>
            <TextField.Root
              type="text"
              id="schedule"
              value={schedule}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                setSchedule(e.target.value)
              }
              size="2"
            />
          </Box>
          <Box>
            <Text as="label" size="2" mb="1" weight="bold">
              Delivery Route
            </Text>
            <TextField.Root
              type="text"
              id="deliveryRoute"
              value={deliveryRoute}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                setDeliveryRoute(e.target.value)
              }
              size="2"
            />
          </Box>
        </Flex>
        <Button
          type="submit"
          mt="4"
          style={{ width: "100%" }}
          disabled={mutation.isPending}
        >
          {mutation.isPending ? "Creating..." : "Create Task"}
        </Button>
        {mutation.isError && (
          <Text mt="2" size="2" color="red">
            Error: {mutation.error.message}
          </Text>
        )}
      </form>
    </Card>
  );
}
