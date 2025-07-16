import { createFileRoute } from "@tanstack/react-router";
import CreateTaskFlow from "../components/CreateTaskFlow";
import LastRuns from "../components/LastRuns";
import { Grid, Flex, Box } from "@radix-ui/themes";

export const Route = createFileRoute("/")({
  component: StartScreen,
});

function StartScreen() {
  return (
    <Box p="4">
      <Grid columns="12" gap="4" width="auto" height="100%">
        <Flex direction="column" gap="3" style={{ gridColumn: "span 8" }}>
          <CreateTaskFlow />
        </Flex>
        <Flex direction="column" gap="3" style={{ gridColumn: "span 4" }}>
          <LastRuns />
        </Flex>
      </Grid>
    </Box>
  );
}
