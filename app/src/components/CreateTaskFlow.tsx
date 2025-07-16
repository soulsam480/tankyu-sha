import { Box, Button, Card, Flex, TextArea } from '@radix-ui/themes'
import React, { useState } from 'react'
import IconAttachment from '~icons/carbon/attachment'
import MessageBubble from './MessageBubble'

interface Message {
  role: 'user' | 'assistant' | 'tool'
  content: string
}

export default function CreateTaskFlow() {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      content: 'I can help you create a new task. What would you like to do?'
    }
  ])
  const [input, setInput] = useState('')

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault()
    if (!input.trim()) return

    const userMessage: Message = { role: 'user', content: input }
    setMessages(prev => [...prev, userMessage])
    setInput('')

    // TODO: Add logic to handle assistant/tool responses
  }

  return (
    <Card size='2' style={{ height: '100%' }}>
      <Flex direction='column' height='100%'>
        <Box flexGrow='1' p='6' style={{ overflowY: 'auto' }}>
          <Flex direction='column' gap='4' height='100%'>
            {messages.map((message, index) => (
              <MessageBubble key={index} message={message} />
            ))}
          </Flex>
        </Box>
        <Box p='4'>
          <form onSubmit={handleSendMessage}>
            <Flex direction='column' gap='3'>
              <TextArea
                value={input}
                onChange={e => setInput(e.currentTarget.value)}
                onKeyDown={e => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault()
                    handleSendMessage(e)
                  }
                }}
                placeholder='Ask me anything...'
                size='3'
              />
              <Flex direction='row' justify='between' align='center'>
                <Flex align='center' gap='2'>
                  <Button variant='ghost' color='gray'>
                    <IconAttachment />
                  </Button>
                  <Button variant='ghost' color='gray'>
                    {/* TODO: Add voice input icon */}
                    Voice
                  </Button>
                </Flex>
                <Button type='submit' variant='solid'>
                  Send
                </Button>
              </Flex>
            </Flex>
          </form>
        </Box>
      </Flex>
    </Card>
  )
}
