## tankyu_sha

> seeker in japaneesse

### What's this ?

1. tankyu-sha is is an AI assisted personal digest tool.
2. the end goal is to keep an eye over a bunch of stuff over the internet
   without having to go to the websites.

The overral system can be seen here [plan.md](plan.md), though it's not updated
in a while. will fix that

### How to run

1. have `ollma` installed on system
2. have both `llama3.2:3b` and `deepseek-r1:7b` plus `nomic-embed-text` models
   installed
3. `mise` is also needed to install all runtimes
4. run `mise install` to get all deps
5. run `bunx playwright install` to install chromium <- rn it tries to get
   system app, has to be configurable
6. now we can run `gleam run` and visit the app at `http://localhost:8080`
7. hit the `queue` button to send some task to the scheduler, it's just a
   process monitor for now

### Roadmap (in no particular order)

- [ ] flatten all actor messages to separate actors <- rn all of them are
      blocked even though we can move ahead
- [ ] actor pool for all actors
- [ ] keep playwright instance alive and every request is a new conetxt + tab or
      reuse same context
- [ ] finish search source
- [ ] expose all config options via UI
  - summarry model, embedding model, or maybe a model per run
  - chromium location <- useful when running outside docker
- [ ] add courier actor to send digest
- [ ] add UI for home page task + source creation
- [ ] add UI for task list
- [ ] add UI for task_runs -> source_runs
- [ ] write a Dockerfile to distribute this
