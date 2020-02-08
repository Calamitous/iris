# Epics
## MVP: Complete!
## Reading/Status: Complete!
## Editing/Deleting: Complete!
## Documentation: In Progress

# For 1.0.8
* Add less-style pagination for long messages
* Add -q/--quiet flag, to create iris message file without user intervention?
* Add integration tests
* Add ability to run with test iris file
* Continue to make loader more durable against corrupted data files
* Time to start refactoring!
* Health check CLI flag
* Create local copies of replied-to messages to limit tampering

# Bugs:
* Is `Time.now.utc.iso8601` working as expected?
* Exclude user's own messages from "unread" count
* Fix message ordering when editing/deleting multiple messages
* Replying implicitly to 24 replied to 6 instead

# Tech debt:
* Flesh out technical sections
* Flesh out tests
* Create Struct to firm up message payload
* Let Message initialization accept params as a hash
* Add check for message file format version
* Build entire topic line, _then_ truncate

# Refactoring
* Split helptext into separate file?

# Features:
* Add ability to fully manage/read messages from CLI?
* Add local timezone rendering
* Add pagiation/less for long message lists
* Add "Mark unread" option
* Add read-only mode if user doesn't want/can't have message file
* Add user muting (~/.iris.muted)
* Add message editing
* JSON API mode
* Check message file size before loading, to prevent giant files from bombing the system.
* Add stats to interactive interface
* Add "private" messages
* Allow shelling out to editor for message editing?

# Fancify interface:
* Readline.completion_proc for tab completion
* Pagination?
* Add "read" message counts to topic line
* Add reader/user count to stats
* Gracefully handle attempt to "r 1 message"
* Highlight names for readability
* Add optional title for topics
* Add message when no topics are found
* Add message troubleshooting tool, for deep data dive
* Add option to skip color

# Icebox
* ncurses client
* customizable prompt
* MOTD
* Add to default startup script to display read count
* Common message file location for the security-conscious
* JSON -> SSI -> Javascript webreader

---

# Completed as of 1.0.5
* Make all output WIDTH-aware
* Add color
* Add full message corpus dump for backup/debugging
* Add startup enviro health check
* Change listing to show last updated timestamp, instead of thread creation timestamp
* Add command-line options to README
* Add documentation for color feature
* Add command-line options to README
* Made message file slightly more human-readable

# Completed as of 1.0.6
* ~Message deletion~
* ~Message editing~
* ~Gracefully handle bad message files~
* ~Fix topic selection when replying without topic ID~
* ~Automatically display topics when opening~
* ~Move display headers into frame line~
* ~Fix truncated message headers being one character too long in topic list~
* ~Status flag fix~
* ~Keep order of message on edit~
* ~Mark unread topics/topics with unread replies in topics list~
* ~Add column headers for topics~
* ~Document new features~
* ~Keep replies on edited topics~
* ~Add unread topic to overall unread count~

# Completed as of 1.0.8
* ~Fix "unread count" bug~
* ~Fix bug when UID has been deleted from /etc/passwd, but user's message file still exists~
* ~Add debug mode to Iris~
* ~Refactor Iris to make it easier to load test files to run with~

