# Iris
## Serverless text-based forum for tilde-likes

Iris is a tiny bit of shared message and file convention that pretends to be forum software.

It is a fully usable message system, designed for use between different users on a single server.

Iris is strictly text-based, requiring no GUI, database, or web servers.

 * [Installation](#installation)
 * [Usage](#usage)
 * [Commands](#commands)
 * [Command-line Options](#command-line-options)
 * [Text Features/Markup](#text-featuresmarkup)
 * [Philosophy](#philosophy)
 * [Tests](#tests)
 * [Cutting A Release](#cutting-a-release)
 * [Technical Bits](#technical-bits)
 * [License](#license)

## Installation

At its core, Iris is simply a single, executable Ruby script.  It has been tested and is known to work with Ruby 2.3.5 and above.  No extra gems or libraries are required.

Copy or symlink `iris.rb` somewhere the whole server can use it; `/usr/local/bin` is a good candidate:

```bash
chmod 755 ./iris.rb
mv ./iris.rb /usr/local/bin/iris
```

## Usage

Iris has a readline interface that can be used to navigate the message corpus.

### Readline Interface Example

```bash
%> iris
Welcome to Iris v. 1.1.3.  Type "help" for a list of commands.; Ctrl-D or 'quit' to leave.

 | ID | U | TIMESTAMP            | AUTHOR                  | TITLE
 |  1 |   | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 |  2 | 1 | 2018-01-24T16:22:05Z | jerry_berry@ctrl-c.club | Suggestions for a...

jimmy_foo@ctrl-c.club>
```

## Commands

 * [[t]opics](#topics)
 * [[u]nread](#unread)
 * [Display topic](#display-topic)
 * [[n]ext](#next)
 * [[c]ompose](#compose)
 * [[r]eply](#reply)
 * [[e]dit](#edit)
 * [[d]elete and un[d]elete](#delete)
 * [[m]ark_read](#mark_read)
 * [mark_all_read](#mark_all_read)
 * [[f]reshen](#freshen)
 * [reset OR clear](#reset-or-clear)
 * [[i]nfo](#info)
 * [[h]elp](#help)

---

### [t]opics
`topics, t    - List all topics`

This outputs a list of top-level topics that have been composed by everyone on the server.

```
jimmy_foo@ctrl-c.club> topics

 | ID | U | TIMESTAMP            | AUTHOR                  | TITLE
 |  1 |   | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 |  2 | 1 | 2018-01-24T16:22:05Z | jerry_berry@ctrl-c.club | Suggestions for a...

```

1. The first column is the topic index.  This is the reference number to use when displaying or replying to a topic.
1. The second column is unread count.  This shows how many messages under this topic you haven't seen.
1. The third column is the timestamp.  This is the server-local time when the topic was composed or last replied to.
1. The fourth column is the author.  This is the user who composed the topic.
1. The fifth column is the title.  This is the truncated first line of the topic.

---

### [u]nread
`unread, u    - List all unread topics`

This outputs a list of top-level topics that have not been read, or have unread messages

```
jimmy_foo@ctrl-c.club> unread

 | ID | U | TIMESTAMP            | AUTHOR                  | TITLE
 |  2 | 1 | 2018-01-24T16:22:05Z | jerry_berry@ctrl-c.club | Suggestions for a...

```

The format of the unread topics list is identical to the format of the [topics](#topics) list

---

### Display topic
`(topic id #) - Read specified topic`

Type in the index of the topic you wish to read.  This will display the topic and all its replies.
```
jimmy_foo@ctrl-c.club> topics

 | ID | U | TIMESTAMP            | AUTHOR                  | TITLE
 |  1 |   | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 |  2 | 1 | 2018-01-24T16:22:05Z | jerry_berry@ctrl-c.club | Suggestions for a...

jimmy_foo@ctrl-c.club> 1
*** [1] On 2018-01-24T05:49:53Z, jimmy_foo@ctrl-c.club posted...-----------------
Welcome!
It's good to see everyone here!
---------------------------------------------------------------------------------

  | === [M2] On 2018-01-30T22:50:38Z, jerry_berry@ctrl-c.club replied...---------
  | Thanks!
  | -----------------------------------------------------------------------------

```

---

### [n]ext
`next, n - Read the next unread topic`

This command displays the first topic which is unread or has unread replies.
```
jimmy_foo@ctrl-c.club> topics

 | ID | U | TIMESTAMP            | AUTHOR                  | TITLE
 |  1 |   | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 |  2 | 1 | 2018-01-24T16:22:05Z | jerry_berry@ctrl-c.club | Suggestions for a...

jimmy_foo@ctrl-c.club> next
*** [2] On 2018-01-24T16:22:05Z, jerry_berry@ctrl-c.club posted...---------------
Suggestions for a tilde home?

I'm trying to decide on a new place in the tildeverse to call home.  Any ideas?
---------------------------------------------------------------------------------

  | === [M4] On 2018-01-30T22:50:38Z, jimmy_foo@ctrl-c.club replied...-----------
  | Have you considered https://ctrl-c.club?
  | -----------------------------------------------------------------------------

```

---

### [c]ompose
`compose, c - Add a new topic`

This allows you to add a new top-level topic to the board.  The first line of your new topic will be used as the topic title.

Iris will allow you to type in your message in the editor you have defined in your shell with the `$EDITOR` environment variable.

If you post an empty message, the system will discard it.

```
jimmy_foo@ctrl-c.club~> compose
Writing a new topic.

new~> How do I spoo the fleem?
new~> It's not in the docs and my boss is asking.  Any help is appreciated!
new~> .
Topic saved!


jimmy_foo@ctrl-c.club~> topics

 | ID | U | TIMESTAMP            | AUTHOR                  | TITLE
 |  1 |   | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 |  2 |   | 2018-01-24T16:22:05Z | jerry_berry@ctrl-c.club | Suggestions for a...
 |  3 | 1 | 2018-01-23T00:22:44Z | jimmy_foo@ctrl-c.club   | How do I spoo the...
```

---

### [r]eply
`reply #, r # - Reply to a specific topic`

Replies are responses to a specific topic -- they only appear when displaying the topic.

Iris will allow you to type in your message in the editor you have defined in your shell with the `$EDITOR` environment variable.

If you post an empty message, the system will discard it.

```
jennie_minnie@ctrl-c.club~> reply 3
Writing a reply to topic 'How do I spoo the fleem?'.

reply~> Simple, you just boondoggle the flibbertigibbet.  That should be in the manual.
reply~> .
Reply saved!

jennie_minnie@ctrl-c.club~> 3

*** [3] On 2018-01-23T00:22:44Z, jimmy_foo@ctrl-c.club posted...-----------------
How do I spoo the fleem?
It's not in the docs and my boss is asking.  Any help is appreciated!
---------------------------------------------------------------------------------

  | === [M5] On 2018-01-31T05:59:27Z, jennie_minnie@ctrl-c.club replied...-------
  | Simple, you just boondoggle the flibbertigibbet.  That should be in the
  | manual.
  | -----------------------------------------------------------------------------
```

---

### [e]dit
`edit #, e # - Edit a topic or message`

Editing a message or topic will replace the message you select with an all-new message.

To select the message you wish to edit, use either the topic index or the message number.

The message number will always start with the capital letter "M", message "M5" for example.

A topic ID will always be strictly numeric, "3" in the following example.

The message or topic ID can be found in square brackets in the informational text above each message.

Iris will allow you to type in your message in the editor you have defined in your shell with the `$EDITOR` environment variable.

If you post an empty message, the system will discard it and the edit will be ignored.

After an edit, a status flag will appear on the message, letting others know the content of the message has been changed.

```
jennie_minnie@ctrl-c.club~> 3

*** [3] On 2018-01-23T00:22:44Z, jimmy_foo@ctrl-c.club posted...-----------------
How do I spoo the fleem?
It's not in the docs and my boss is asking.  Any help is appreciated!
---------------------------------------------------------------------------------

  | === [M5] On 2018-01-31T05:59:27Z, jennie_minnie@ctrl-c.club replied...-------
  | Simple, you just boondoggle the flibbertigibbet.  That should be in the
  | manual.
  | -----------------------------------------------------------------------------

jennie_minnie@ctrl-c.club~> edit M5
Editing message 'Simple, you just boondoggle the flibbertigibbet.  That shoul...'

edit~> Simple, you just boondoggle the flibbertigibbet.  That's in the manual on page 45.
edit~> .
Message edited!

jennie_minnie@ctrl-c.club~> 3

*** [3] On 2018-01-23T00:22:44Z, jimmy_foo@ctrl-c.club posted...-----------------
How do I spoo the fleem?
It's not in the docs and my boss is asking.  Any help is appreciated!
---------------------------------------------------------------------------------

  | === [M5] (edited) On 2018-01-31T05:59:27Z, jennie_minnie@ctrl-c.club repli...
  | Simple, you just boondoggle the flibbertigibbet.  That's in the manual on
  | page 45.
  | -----------------------------------------------------------------------------
```

---

### [d]elete
`delete #, d #, undelete # - Delete or undelete a topic or message`

Deleting a message or topic will remove the message you select.

To select the message you wish to delete, use either the topic index or the message number.

The message number will always start with the capital letter "M", message "M5" for example.

A topic ID will always be strictly numeric, "3" in the following example.

The message or topic ID can be found in square brackets in the informational text above each message.

After a deletion, a status flag will appear on the message, letting others know the content of the message has been deliberately removed.

If you wish to revert your deletion, "delete" the deleted message or topic ID to restore it.

The `undelete` command is provided as a mnemonic convenience; it is identical in function to the `delete` command.
```
jennie_minnie@ctrl-c.club~> 3

*** [3] On 2018-01-23T00:22:44Z, jimmy_foo@ctrl-c.club posted...-----------------
How do I spoo the fleem?
It's not in the docs and my boss is asking.  Any help is appreciated!
---------------------------------------------------------------------------------

  | === [M5] On 2018-01-31T05:59:27Z, jennie_minnie@ctrl-c.club replied...-------
  | Simple, you just boondoggle the flibbertigibbet.  That should be in the
  | manual.
  | -----------------------------------------------------------------------------

jennie_minnie@ctrl-c.club~> delete M5
Deleted message 'Simple, you just boondoggle the flibbertigibbet.  That shoul...'

jennie_minnie@ctrl-c.club~> 3

*** [3] On 2018-01-23T00:22:44Z, jimmy_foo@ctrl-c.club posted...-----------------
How do I spoo the fleem?
It's not in the docs and my boss is asking.  Any help is appreciated!
---------------------------------------------------------------------------------

  | === [M5] (deleted) On 2018-01-31T05:59:27Z, jennie_minnie@ctrl-c.club repl...
  | -----------------------------------------------------------------------------

jennie_minnie@ctrl-c.club~> undelete M5
Undeleted message 'Simple, you just boondoggle the flibbertigibbet.  That sho...'

jennie_minnie@ctrl-c.club~> 3

*** [3] On 2018-01-23T00:22:44Z, jimmy_foo@ctrl-c.club posted...-----------------
How do I spoo the fleem?
It's not in the docs and my boss is asking.  Any help is appreciated!
---------------------------------------------------------------------------------

  | === [M5] On 2018-01-31T05:59:27Z, jennie_minnie@ctrl-c.club replied...-------
  | Simple, you just boondoggle the flibbertigibbet.  That should be in the
  | manual.
  | -----------------------------------------------------------------------------

```

---

### [m]ark_read
`mark_read, m   - Mark a topic read`

Mark a topic and all its replies as read without displaying them.

---

### [m]ark_all_read
`mark_all_read   - Mark all messages as read`

Marks all topics and their replies as read without displaying them.

---

### [f]reshen
`freshen, f   - Reload to get any new messages`

This command reloads all users' message files to get any new messages that might have come in since you started the program.

---

### reset OR clear
`reset, clear - Fix screen in case of text corruption`

This clears the screen and resets the cursor. If you experience screen corruption due to wide characters or terminal resizing, this may fix your visual issues.

---

### [i]nfo
`info, i      - Display Iris version and message stats`

This outputs the current version of Iris, along with messsage, topic, and author counts.

```bash
jennie_minnie@ctrl-c.club~> info

Iris 1.1.3
22 topics, 0 unread.
50 messages, 0 unread.
10 authors.
```

---

### [h]elp
`help, h, ?   - Display help text`

This displays helpful reminders of the commands that Iris supports.

## Command-line Options

There are a few options you can pass in from the command-line:

 * [--debug](#--debug)
 * [--dump, -d](#--dump-d)
 * [--help, -h](#--help-h)
 * [--interactive, -i](#--interactive-i)
 * [--mark-all-read](#--mark-all-read)
 * [--stats, -s](#--stats-s)
 * [--test-file, -s](#--test-file)
 * [--version, -v](#--version-v)

### --debug

This option turns on debug mode.  Warnings and errors will be output as the program is used.

Having these messages constantly appear can be distracting or annoying during regular Iris usage, but are useful when tracking down issues.

This option works in both interactive and non-interactive mode.

---

### --dump/-d

This reads the entire message corpus and outputs it as a stream of JSON data, suitable for piping into a backup file, `jq` parser, or similar.

This command does not enter Iris' interactive mode.

---

### --help/-h

This command displays a complete list of options that Iris recognizes.

---

### --interactive/-i

This command enters Iris' interactive mode, the default mode with which users can compose and read topics and replies.

This is the mode that Iris enters if no options are passed on the command-line.

---

### --mark-all-read

This command simply marks every message as read in Iris.  It's a quick way to get to "Irisbox Zero".

---

### --stats/-s

This outputs the current version of Iris, along with messsage, topic, and author counts.

This command does not enter Iris' interactive mode.

```bash
iris --stats
```

```bash
Iris 1.1.3
22 topics, 0 unread.
50 messages, 0 unread.
10 authors.
```

---

### --test-file/-f

```bash
iris --test-file junk.messages.iris
```

This option forces Iris to load the specified message file, instead of scanning the `/home` directory.

This option works in both interactive and non-interactive mode.

---

### --version/-v

This displays the current version of Iris and exits.

```bash
iris --version
```

```bash
Iris 1.1.3
```

## Text Features/Markup

### Color

Iris supports 7 colors and 4 text features.

#### Colors

| Marker | Color   |
|:------:|:--------|
| r      | Red     |
| g      | Green   |
| y      | Yellow  |
| b      | Blue    |
| m      | Magenta |
| c      | Cyan    |
| w      | White   |

#### Text Features

| Marker | Feature    |
|:------:|:-----------|
| n      | Normal     |
| i      | Intense    |
| u      | Underlined |
| v      | Reversed   |

#### Markup

Colors and Text Features are applied by a simple markup.  Surround the text you want colored with an opening curly brace (`{`), add some number of text modification markers (`riu`, for example),  and `}`), and close with a closing curly brace (`}`).

For example, if you have the text:

```
The blue fox and the yellow dog
```

...and you wanted to color it appropriately, you would wrap the text "blue fox" and "yellow dog" like so:

```
The {b blue fox} and the {y yellow dog}
```

The result, in your final message, would look like:

![blue_fox_and_yellow_dog.png](docs/images/blue_fox_and_yellow_dog.png)

---

Text features can be added as well:

```
The {b blue fox} {u will} jump over the {y yellow dog}
```

![blue_fox_jumping.png](docs/images/blue_fox_jumping.png)

---

A color can be combined with multiple text features:

```
The {b blue fox} {riuv will} jump over the {y yellow dog}
```

![blue_fox_really_jumping.png](docs/images/blue_fox_really_jumping.png)

---

Marker order does not matter.  These two statements are equivalent:

```
The {bv blue fox} {riuv will} jump over the {yi yellow dog}
The {vb blue fox} {uirv will} jump over the {iy yellow dog}
```

---

If you want to type a curly brace, preface it with a backslash (`\`):

```
No colors for me, please.  I just want to \{ write: code \}
```

...yields:

```
No colors for me, please.  I just want to { write: code }
```

---

#### Color and Text Feature Sample

![color_and_text_feature_sample.png](docs/images/color_and_text_feature_sample.png)

---

#### Caveats

Color and text feature markup cannot be nested.  It won't break anything, but it will probably not look like you are expecting.

## Philosophy

Iris must:
  * Be a single file
    * There should be no specific directory structure or complicated setup required.
    * Run a single file, answer one question, and you should be going with Iris!
  * Not require administrator intervention to install
    * Any user on a tilde, or with his or her own server, should be able to start using Iris just by running the file.
  * Not require any other software to function
    * No databases, web servers, GUIs, or frameworks are require to use Iris fully.
  * Require only Ruby
    * Not everybody uses Ruby or is familiar with the Ruby ecosystem.
    * Installing gems and libraries can be a major hassle if you don't have admin access or if there are library version conflicts.
    * Iris needs no extra gems or libraries to function.
  * Be durable
    * A user deleting or modifying his or her messages or message file should not break Iris.
    * Deleted or edited messages should leave flags or placeholders for other users to know that other content was there before.
    * The Iris client should expect that any message file could be missing, altered, or corrupted, and should handle those cases gracefully.
  * Be portable
    * All Iris data files should be human-readable (and -editable, in a pinch)
    * The use of the official Iris client should be optional for a user to manage his or her messages.  A text editor should suffice.
    * Other clients which follow the Iris file format should work seamlessly with the official Iris client.
  * Be secure
    * Message files should be owned and only editable by their author.
    * Iris should warn the user if this is not the case.
  * Be a teacher
    * Code should be clean, well-organized, and readable.
  * Be limited in scope
    * The source code should not exceed 1,000 SLOC

## Tests

The one place we're breaking the rules on requiring gems is in the tests.  Mocha's just too good.  :)  To run the tests, you can install the following (these will end up in your user directory, to minimize the chances of interfering with system gems).

```bash
gem install --user-install minitest
gem install --user-install mocha
```

To run the tests:

```bash
ruby tests/iris_test.rb
```

```bash
Run options: --seed 11507

# Running:

.........................SSS.......SS.......S.....SSSSSSS....SSSSS

Finished in 0.107785s, 612.3294 runs/s, 677.2734 assertions/s.

66 runs, 73 assertions, 0 failures, 0 errors, 18 skips

You have skipped tests. Run with --verbose for details.
```

## Cutting A Release

### Prep
* Make all updates in an appropriately named branch. (ie. `1.1.3`)
* Make sure all commits are clean.
* Make sure tests pass.

### Updates
* Change version number in `iris.rb`
* Change version numbers in documentation `README.md`
* Add new version and details to `CHANGELOG`
* Create new commit for release (Named "Bump Iris version to 1.1.3" or similar)

### Make the Sausage
* Push the branch
  * `git push origin`
* Merge the branch (Fast-forward only, for a linear commit history)
* Tag the release
  * `git tag 1.1.3`
* Push the tags
  * `git push origin --tags`

## Technical Bits

  * [Dependencies](#dependencies)
  * [Conventions](#conventions)
  * [Message Files](#message-files)
  * [Messages](#messages)
    * [Message Hash](#message-hash)
      * [Bad Hashes](#bad-hashes)
    * [Edit Chain](#edit-chain)
    * [Deleted Messages](#deleted-messages)
  * [Topic List](#topic-list)
  * [Replies](#replies)

### Dependencies

While trying to stay reasonably lightweight, Iris does dependend on a few tools being installed:

* `ls` is used to get a list of all the Iris message files on the system.
* `hostname` is used to find the name of the server Iris is running on.
* `tput` is used to get the terminal reset command.

### Conventions

Iris leans heavily on convention.  Iris' security and message authentication is provided by filesystem permissions and message hashing.

### Message Files

Each user has their own message file.  This is a JSON file containing all the messages that the user has authored.  It is named `.iris.messages` and is located in the user's home directory.

`/home/jimmy_foo/.iris.messages`

In order to operate correctly and safely, this file _must_ be:
* World-readable
* Owner-writable
* Non-executable
* Owned by the user account that it will be storing messages for

```bash
%> ls -la ~/.iris.messages
-rw-r--r-- 1 jimmy_foo jimmy_foo /home/jimmy_foo/.iris.messages
```

### Messages

Messages fall into one of two categories: topics and replies.  Topics are top-level messages. Replies are messages that are attached to a topic.

The message structure is as follows:

```
{
  "hash": str,
  "edit_hash": str,
  "is_deleted": bool,
  "data": {
    "author": str,
    "parent": str,
    "timestamp": str,
    "message": str
  }
}
```

Each field is as follows:

* author: The username of the user who created the message, with the server hostname attached with an @ symbol (ie. `jerry_berry@ctrl-c.club`).
* message: The text of the message.  The first line is the title of the message.
* hash: Each message is SHA1 hashed for verification and uniqueness.  The author, parent hash, timestamp, and message values go into the hash. (see [Message Hash](#message-hash) for details)
* parent: If the message is a reply, this holds the hash of the topic it's associated with.
* timestamp: The GMT timestamp of when the message was created.
* edit_hash: When a message is edited, a new message is created-- this field holds the hash of the modified message.  The client follows the chain of edit hashes to end up at the final, edited message to display.  This lets us keep an "undo" history (not yet implemented) and is a marker so the client can display a marker that the message has been edited.
* is_deleted: This is a boolean field that marks whether a message has been deleted.  The message is retained so that the structure of topics and replies can be maintained.
* errors (not saved to the file): This is where any issues are held for display.  Examples of errors are unparseable usernames or invalid hashes.

#### Message Hash

Each message is SHA1 hashed for verification and uniqueness.

The hash is created by putting  `author`, `parent`, `timestamp`, and `message` go into a JSON-formatted string.  This string should include no extra whitespace.

For example:

The following message:

author: `jerry_berry@ctrl-c.club`
parent: null
timestamp: `2021-11-25T06:35:34Z`
message: `Howdy!`

Would be turned into the following JSON string, in this order:

```
{"author":"jerry_berry@ctrl-c.club","parent":null,"timestamp":"2021-11-25T06:35:34Z","message":"Howdy!"}
```

This string would then be hashed using SHA1:

```
\xBD\xFD[D\xA0\xF0\xBFw`\x14\xF8)\xCA\xC9n\xFA-\x82\xB9\xBC
```

This hash is then base64 encoded:

```
vf1bRKDwv3dgFPgpyslu+i2Cubw=\n
```

This is the "key" that is used to uniquely identify this version of the message.

##### Bad Hashes
#### Edit Chain
#### Deleted Messages

### Topic List

### Replies

## License
GPLv2
