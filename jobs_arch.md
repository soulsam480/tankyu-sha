## How taks are processed

1. scheduler
   1. look at taks, then find taks based on delivery time or schedule
   2. create a task run and schedule it in the executor actor
   3. find all sources of the task and then create source runs of them
2. executor
   1. executes jobs (task run or source run) sent by the scheduler
   2. for a source run <- pull source from DB and then run it via content/runner
   3. once source is ran
      1. create digest and store it in source run
      2. chunk -> embed -> store the original text content
   4. inform task run that all sources have been run and it's time to deliver
      the digest
      1. read all child source runs
      2. take all source digests and then produce a task digest
      3. deliver it
3. Courier
   1. take task run
   2. deliver it
