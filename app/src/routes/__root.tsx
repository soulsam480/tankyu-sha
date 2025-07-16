import { Box, Flex } from '@radix-ui/themes'
import type { QueryClient } from '@tanstack/react-query'
import { createRootRouteWithContext, Outlet } from '@tanstack/react-router'
import { TanStackRouterDevtools } from '@tanstack/react-router-devtools'
import Sidebar from '../components/Sidebar'
import TanStackQueryLayout from '../integrations/tanstack-query/layout.tsx'
import '../styles.css'

interface MyRouterContext {
  queryClient: QueryClient
}

export const Route = createRootRouteWithContext<MyRouterContext>()({
  component: () => (
    <Flex height='100vh'>
      <Sidebar />
      <Flex direction='column' flexGrow='1' style={{ overflow: 'hidden' }}>
        <Box flexGrow='1' style={{ overflowY: 'auto' }}>
          <main>
            <Outlet />
          </main>
        </Box>
        <TanStackRouterDevtools />
        <TanStackQueryLayout />
      </Flex>
    </Flex>
  )
})
