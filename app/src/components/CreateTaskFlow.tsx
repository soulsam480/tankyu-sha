import React, { useState } from "react";
import IconAttachment from "~icons/carbon/attachment";
import IconSend from "~icons/carbon/send-alt";
import MessageBubble from "./MessageBubble";

interface Message {
  role: "user" | "assistant" | "tool";
  content: string;
}

export default function CreateTaskFlow() {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: "assistant",
      content: "I can help you create a new task. What would you like to do?",
    },
  ]);
  const [input, setInput] = useState("");

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;

    const userMessage: Message = { role: "user", content: input };
    setMessages((prev) => [...prev, userMessage]);
    setInput("");

    // TODO: Add logic to handle assistant/tool responses
  };

  return (
    <div className="flex flex-col h-full bg-white border border-secondary-200 rounded-lg">
      <div className="flex-1 overflow-y-auto p-6 space-y-4">
        {messages.map((message, index) => (
          <MessageBubble key={index} message={message} />
        ))}
      </div>
      <div className="p-4 bg-white">
        <div className="relative">
          <form
            onSubmit={handleSendMessage}
            className="relative flex flex-col p-4 border border-secondary-200 rounded-lg shadow-sm"
          >
            <textarea
              value={input}
              onChange={(e) => setInput(e.currentTarget.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  handleSendMessage(e);
                }
              }}
              placeholder="Ask me anything..."
              className="w-full p-2 pr-12 border-none resize-none focus:ring-2 focus:ring-primary-500 focus:outline-none"
              rows={1}
            />
            <button
              type="submit"
              className="absolute right-4 top-1/2 -translate-y-1/2 p-2 bg-black text-white rounded-full hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2"
            >
              <IconSend />
            </button>
            <div className="flex items-center pt-2 mt-2 border-t border-primary-200">
              {/* Placeholder for action icons */}
              <button className="p-2 text-primary-500 hover:text-primary-700">
                <IconAttachment />
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
