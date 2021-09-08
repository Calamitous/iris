# Epics
### MVP: Complete!
### Reading/Status: Complete!
### Editing/Deleting: Complete!
### Documentation: In Progress

# Work Items

### Documentation
* Flesh out technical sections

### Bugs
* Replying implicitly to 24 replied to 6 instead-- remove implicit reply?
* Is `Time.now.utc.iso8601` working as expected?
  * Fix bug when people are posting from different time zones
  * Fix message ordering when editing/deleting multiple messages
* Gracefully handle attempt to "r 1 message"

### Features
* Add "unread" marker to topic replies
* Allow shelling out to editor for message editing
  * https://github.com/Calamitous/iris/issues/2
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

# Changelog

## 1.0.12
* Add Asara's "mark all read" functionality
* Fix(?) bug with handling broken UTF-8 characters
* Add feature to read the next unread topic ("next")
* Exclude user''s own messages from "unread" count

## 1.0.11
* Speed up the topic listing significantly
* Add 'unread' (short form 'u') to only list topics with unread messages
* Add 'mark_unread' (short form 'm') to mark topics as read without displaying them
* Tweaks to help text
* Default main listing to unread topics instead of listing all topics
* Updates to the way screen dimensions are calculated
* Preliminaary work to support pagination
* Change permissions message from error to warning so it only shows in debug mode

## 1.0.10
* ~Fix bug causing system to crash when a user removes read permissions from their directory/iris.messages file~

## 1.0.9
* ~Stop checking domain on user validation~
* ~Fix bug causing color overflow when color tags break.~  Special thanks go out to Japanoise (https://github.com/japanoise) for reporting this bug!

## 1.0.8
* ~Fix bug when UID has been deleted from /etc/passwd, but user''s message file still exists~
* ~Add debug mode to Iris~
* ~Refactor Iris to make it easier to load test files to run with~

## 1.0.7
* ~Fix "unread count" bug~

## 1.0.6
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

## 1.0.5
* ~Make all output WIDTH-aware~
* ~Add color~
* ~Add full message corpus dump for backup/debugging~
* ~Add startup enviro health check~
* ~Change listing to show last updated timestamp, instead of thread creation timestamp~
* ~Add command-line options to README~
* ~Add documentation for color feature~
* ~Add command-line options to README~
* ~Made message file slightly more human-readable~
