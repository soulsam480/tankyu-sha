import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createTask } from "../api/models/Task";
import type { Task } from "../api/models/Task";

// A simple regex to find URLs in a string
const URL_REGEX = /(https?:\/\/[^\s]+)/g;

export default function CreateTaskFlow() {
  const queryClient = useQueryClient();
  const [step, setStep] = useState(1);
  const [prompt, setPrompt] = useState("");
  const [taskDetails, setTaskDetails] = useState<Partial<Task>>({});
  const [urls, setUrls] = useState<string[]>([]);

  const mutation = useMutation({
    mutationFn: (
      newTask: Omit<
        Task,
        "id" | "created_at" | "updated_at" | "active" | "last_run_at"
      >,
    ) => createTask(newTask),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
      setStep(1); // Reset flow
      setPrompt("");
    },
  });

  const handleNext = () => {
    const foundUrls = prompt.match(URL_REGEX);
    if (foundUrls) {
      // Scenario: Known URL
      setUrls(foundUrls);
      setTaskDetails({
        topic: prompt.replace(URL_REGEX, "").trim(),
        // a default schedule
        schedule: "every saturday",
      });
      setStep(2);
    } else {
      // Scenario: Ambiguous or Simple Topic
      // For now, we'll treat them the same and move to a generic confirmation.
      setTaskDetails({
        topic: prompt,
        schedule: "every day at 10am",
      });
      setStep(3);
    }
  };

  const handleFinalize = () => {
    const finalTask = {
      topic: taskDetails.topic || "",
      schedule: taskDetails.schedule || "",
      delivery_route: "email", // default
      // In a real app, you'd get this from the user
    };
    mutation.mutate(finalTask);
  };

  const renderStep = () => {
    switch (step) {
      case 1:
        return (
          <div>
            <h1 className="text-2xl font-bold mb-4">
              What task can I help you with?
            </h1>
            <div className="flex items-center space-x-2 mb-4">
              <textarea
                className="w-full p-2 border rounded"
                placeholder="e.g., keep an eye over https://www.linkedin.com/company/withdefault weekly on saturdays."
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
              />
            </div>
            <button
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
              onClick={handleNext}
            >
              Next
            </button>
          </div>
        );
      case 2: // Known URL Confirmation
        return (
          <div>
            <h2 className="text-xl font-bold mb-4">Confirm Task</h2>
            <div className="p-4 border rounded bg-gray-50 mb-4">
              <p>
                I'll watch over their profile and give you information every
                saturday
              </p>
              <div className="mt-4 p-2 bg-white border rounded">
                <p className="font-semibold">New task</p>
                <p>- topic: watch over withdefault profile</p>
                <p>- schedule: {taskDetails.schedule}</p>
                <p>- url: {urls[0]}</p>
              </div>
            </div>
            <button
              className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
              onClick={handleFinalize}
              disabled={mutation.isPending}
            >
              {mutation.isPending ? "Creating..." : "This is fine"}
            </button>
          </div>
        );
      case 3: // Simple/Ambiguous Topic Confirmation
        return (
          <div>
            <h2 className="text-xl font-bold mb-4">Confirm Task</h2>
            <div className="p-4 border rounded bg-gray-50 mb-4">
              <p>
                Cool, I'll look around the internet about {taskDetails.topic}{" "}
                and summarise that for you at {taskDetails.schedule}.
              </p>
              <div className="mt-4 p-2 bg-white border rounded">
                <p className="font-semibold">New task</p>
                <p>- topic: {taskDetails.topic}</p>
                <p>- schedule: {taskDetails.schedule}</p>
              </div>
            </div>
            <button
              className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
              onClick={handleFinalize}
              disabled={mutation.isPending}
            >
              {mutation.isPending ? "Creating..." : "Enter"}
            </button>
          </div>
        );
      default:
        return <div>Invalid step</div>;
    }
  };

  return (
    <div>
      {renderStep()}
      {mutation.isError && (
        <p className="mt-2 text-sm text-red-600">
          Error: {mutation.error.message}
        </p>
      )}
    </div>
  );
}
