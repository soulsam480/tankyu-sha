import { Box, Button, Flex, Heading } from '@radix-ui/themes'
import { Link } from '@tanstack/react-router'
import IconRun from '~icons/carbon/run'
import IconSettings from '~icons/carbon/settings'
import IconTask from '~icons/carbon/task'

export default function Sidebar() {
  return (
    <Box width='288px' p='4' style={{ backgroundColor: 'var(--gray-2)' }}>
      <Flex justify='between' align='center' p='2' mb='4'>
        <Flex align='center'>
          <Heading as='h1' size='5' ml='2'>
            Tankyu-Sha
          </Heading>
        </Flex>
      </Flex>

      <Box px='2' mb='4'>
        <Button
          variant='solid'
          size='2'
          style={{ width: '100%', textAlign: 'left' }}
          asChild
        >
          <Link to='/'>
            <Flex align='center' justify='start' gap='2'>
              <IconTask />
              New Task
            </Flex>
          </Link>
        </Button>
      </Box>

      <Flex direction='column' flexGrow='1' px='2' py='4' gap='3'>
        <nav>
          <Button variant='ghost' size='2' style={{ width: '100%' }} asChild>
            <Link
              to='/tasks'
              activeProps={{
                style: {
                  backgroundColor: 'var(--accent-3)',
                  fontWeight: 'bold'
                }
              }}
            >
              <IconTask />
              Tasks
            </Link>
          </Button>
          <Button variant='ghost' size='2' style={{ width: '100%' }} asChild>
            <Link
              to='/runs'
              activeProps={{
                style: {
                  backgroundColor: 'var(--accent-3)',
                  fontWeight: 'bold'
                }
              }}
            >
              <IconRun style={{ marginRight: '12px' }} />
              Runs
            </Link>
          </Button>
        </nav>
      </Flex>

      <Box pt='4' style={{ borderTop: '1px solid var(--gray-5)' }}>
        <Button
          variant='ghost'
          size='2'
          style={{ width: '100%', textAlign: 'left' }}
          asChild
        >
          <Link
            to='/settings'
            activeProps={{
              style: { backgroundColor: 'var(--accent-3)', fontWeight: 'bold' }
            }}
          >
            <IconSettings style={{ marginRight: '12px' }} />
            Settings
          </Link>
        </Button>
      </Box>
    </Box>
  )
}
