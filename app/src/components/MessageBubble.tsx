import { Card, Text, Flex } from "@radix-ui/themes";

interface Message {
  role: "user" | "assistant" | "tool";
  content: string;
}

interface MessageBubbleProps {
  message: Message;
}

export default function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === "user";

  return (
    <Flex justify={isUser ? "end" : "start"}>
      <Card
        style={{
          maxWidth: "80%",
          backgroundColor: isUser ? "var(--accent-9)" : "var(--gray-3)",
          color: isUser ? "white" : "var(--gray-12)",
        }}
      >
        <Text>{message.content}</Text>
      </Card>
    </Flex>
  );
}
