import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { getTasks } from "../api/models/Task";
import type { Task } from "../api/models/Task";

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
    <div className="p-4">
      <h1 className="text-2xl font-bold mb-4">Tasks</h1>
      <CreateTaskForm />
      <ul className="space-y-2">
        {tasks?.map((task: Task) => (
          <TaskItem key={task.id} task={task} />
        ))}
      </ul>
    </div>
  );
}
