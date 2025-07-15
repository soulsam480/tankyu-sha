interface Message {
  role: "user" | "assistant" | "tool";
  content: string;
}

interface MessageBubbleProps {
  message: Message;
}

export default function MessageBubble({ message }: MessageBubbleProps) {
  return (
    <div
      className={`flex items-start gap-4 ${
        message.role === "user" ? "justify-end" : "justify-start"
      }`}
    >
      <div
        className={`rounded-lg px-4 py-2 max-w-2xl break-words ${
          message.role === "user"
            ? "bg-primary-500 text-white"
            : "bg-secondary-100 text-gray-800"
        }`}
      >
        {message.content}
      </div>
    </div>
  );
}
