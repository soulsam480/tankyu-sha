import { Link } from "@tanstack/react-router";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { deleteTask } from "../api/models/Task";
import type { Task } from "../api/models/Task";

interface TaskItemProps {
  task: Task;
}

export function TaskItem({ task }: TaskItemProps) {
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: (id: number) => {
      return deleteTask(id);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
    },
  });

  return (
    <li className="p-4 border rounded-lg flex justify-between items-center">
      <div>
        <p className="font-semibold">{task.topic}</p>
        <p className="text-sm text-gray-500">{task.schedule}</p>
      </div>
      <div className="flex items-center space-x-2">
        <Link
          to="/tasks/$taskId/runs"
          params={{ taskId: task.id.toString() }}
          className="text-blue-500 hover:underline"
        >
          View Runs
        </Link>
        <button
          onClick={() => mutation.mutate(task.id)}
          className="bg-red-500 text-white py-1 px-3 rounded-md hover:bg-red-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
          disabled={mutation.isPending}
        >
          {mutation.isPending ? "Deleting..." : "Delete"}
        </button>
      </div>
    </li>
  );
}
