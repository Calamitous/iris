# Epics
## MVP: Complete!
## Reading/Status: Complete!
## Editing/Deleting: In Progress
## Documentation: In Progress

# For 1.0.6
* Message deletion
* Message editing
  * Allow shelling out to editor for message editing?
* Gracefully handle bad message files
* Fix topic selection when replying without topic ID
* Automatically display topics when opening
* Add column headers for topics
* Mark unread topics/topics with unread replies in topics list
* Move display headers into frame line

# Bugs:
* Is `Time.now.utc.iso8601` working as expected?
* Exclude user's own messages from "unread" count

# Tech debt:
* Flesh out technical sections
* Flesh out tests
* Add integration tests
* Create Struct to firm up message payload
* Let Message initialization accept params as a hash
* Add check for message file format version

# Refactoring
* Split helptext into separate file?

# Features:
* Add read-only mode if user doesn't want/can't have message file
* Add user muting (~/.iris.muted)
* Add message editing
* JSON API mode
* Check message file size before loading, to prevent giant files from bombing the system.
* Add stats to interactive interface
* Add "private" messages

# Fancify interface:
* Add (read/unread) counts to topic line
* Add reader/user count to stats
* Gracefully handle attempt to "r 1 message"
* Highlight names for readability
* Readline.completion_proc for tab completion
* Pagination?
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
