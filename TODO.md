# Epics
### MVP: Complete!
### Reading/Status: Complete!
### Editing/Deleting: Complete!
### Documentation: In Progress

# Work Items

### Documentation
* Flesh out technical sections

### Bugs
* Is `Time.now.utc.iso8601` working as expected?
  * Fix bug when people are posting from different time zones
  * Fix message ordering when editing/deleting multiple messages
* Gracefully handle attempt to "r 1 message"

### Features
* Add pagination/less for long message lists
  * https://github.com/Calamitous/iris/issues/1
* Add local timezone rendering
* CLI option to show response count to threads the user authored
* Search/regex function to find all messages

### Tech debt
* Flesh out tests
* Add integration tests
* Create Struct to firm up message payload
* Let Message initialization accept params as a hash
* Add check for message file format version
* Build entire topic line, _then_ truncate
* Continue to make loader more durable against corrupted data files
* Condense generated color codes (color resets are especially noisy)
* Check message file size before loading, to prevent giant files from bombing the system.

### Backlog
* Add reader/user count to stats
* Add "already read" message counts to topic line
* Add "already read" message counts to statistics
* Add "Mark unread" option
* Add read-only mode if user doesn't want/can't have message file
* Add user muting (~/.iris.muted)
* Add stats to interactive interface
* Readline.completion_proc for tab completion
* Highlight names for readability
* Add message when no topics are found
* Add option to skip color

### Icebox
* Add message troubleshooting tool, for deep data dive
* Add optional title for topics
* Health check CLI flag?
* Add -q/--quiet flag, to create iris message file without user intervention?
* Add "private" messages
* JSON API mode
* Create local copies of replied-to messages to limit tampering?
* Add ability to fully manage/read messages from CLI?
* ncurses client
* customizable prompt
* MOTD/Title?
* Add to default startup script to display read count
* Common message file location for the security-conscious
* JSON -> SSI -> Javascript webreader

