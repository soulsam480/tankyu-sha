### outcome

- daily digest of
  - topic
  - specific site
- questionnaire on digested content
  - keeping context of last digest
  - Context of n previous digests?

### Tentative UX

#### adding a new task

- ask for a topic
  - limited to x count
  - Inform to make it concise and clear enough for better search results
- search and keep results
- Do you want to keep an eye over x specific site or want a digest?
- yes
  - Site not found in results, ask for site URL to narrow down search results
  - re search and keep results
  - At this point we should inform that the URL should not change, i.e. it
    should be a permalink (a profile link?)
  - Assume it's a feed and make the source a feed source
- no
  - Here we just need to search internet, take latest results and run them
    through content runners.
  - Ask for how many pages we should look at
  - Is it news? Inform it yields better results
- Ask for time of delivery
- Save this as a Task.
- Toggle active/inactive task

#### looking at a digest

- Accessible via URL
- allow asking follow up questions
  - Embed vectors related to question
- Show related runs <- that collected information for this digest
- show related task
- digest follow up questions history

### task run history

- Task runs and their child source runs
- status of runs
- re-run a task

#### task edit/delete

### System in detail

- Storage in SQLite
  - Tasks
    - topic
    - related source | nil
    - active
    - delivery time
    - delivery route
      - email
      - more?
  - Sources <- only persisted sources
    - link
    - kind
      - news
      - search
      - feed
    - meta
  - Source_Runs
    - <- parent task run
    - <- related source
      - persisted
      - dynamic <- point in time storage
    - status
      - running
      - errored
      - ran
      - digesting
      - vectorized (think)
      - done
    - related digest
    - Sha of this run so that we can compare if the data is still same
      - think about this
  - Task_Runs
    - <- related task
    - digest
    - status
      - running
      - errored
      - ran
      - digesting
      - done
  - Digest
    - content
    - related task
    - related run
    - meta
