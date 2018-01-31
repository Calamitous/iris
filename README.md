# Iris
## Serverless text-based forum for tilde-likes

### Installation

At its core, Iris is simply a single, executable Ruby script.  It has been tested and is known to work with Ruby 2.3.5.  No extra gems or libraries are required.

Copy or symlink `iris.rb` somewhere the whole server can use it; `/usr/local/bin` is a good candidate:

```
chmod 755 ./iris.rb
mv ./iris.rb /usr/local/bin/iris
```

### Usage

Iris has a readline interface that can be used to navigate the message corpus.

#### Readline Interface Example
```
%> iris
Welcome to Iris v. 1.0.0.  Type "help" for a list of commands.
jimmy_foo@ctrl-c.club> topics

 | 1 | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 | 2 | 2018-01-24T16:13:05Z | jerry_berry@ctrl-c.club | Suggestions for improv...

jimmy_foo@ctrl-c.club>
```

### Commands

#### [t]opics
`topics, t    - List all topics`

This outputs a list of top-level topics that have been composed by everyone on the server.

```
jimmy_foo@ctrl-c.club> topics

 | 1 | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 | 2 | 2018-01-24T16:13:05Z | jerry_berry@ctrl-c.club | Suggestions for improv...

```

1. The first column is the topic index.  This is the reference number to use when displaying or replying to a topic.
1. The second column is the timestamp.  This is the server-local time when the topic was composed.
1. The third column is the author.  This is the user who composed the topic.
1. The fourth column is the title.  This is the truncated first line of the topic.

#### Display topic
`# (topic id) - Read specified topic`

Type in the index of the topic you wish to read.  This will display the topic and all its replies.
```
jimmy_foo@ctrl-c.club> topics

 | 1 | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 | 2 | 2018-01-24T16:13:05Z | jerry_berry@ctrl-c.club | Suggestions for improv...

jimmy_foo@ctrl-c.club> 1
*** On 2018-01-24T05:49:53Z, jimmy_foo@ctrl-c.club posted...
---------------------------------------------------------------------------------
Welcome!
It's good to see everyone here!
---------------------------------------------------------------------------------
=== On 2018-01-30T22:50:38Z, jerry_berry@ctrl-c.club replied...
---------------------------------------------------------------------------------
Thanks!
---------------------------------------------------------------------------------

```

#### [c]ompose
`compose, c    - Add a new topic`

This allows you to add a new top-level topic to the board.  The first line of your new topic will be used as the topic title.

The line editor is quite basic.  Enter your message, line-by-line, and type a single period on a line by itself to end the message.

If you post an empty message, the system will discard it.

```
jimmy_foo@ctrl-c.club~> compose
Writing a new topic.  Type a period on a line by itself to end message.

new~> How do I spoo the fleem?
new~> It's not in the docs and my boss is asking.  Any help is appreciated!
new~> .
Topic saved!


jimmy_foo@ctrl-c.club~> topics

 | 1 | 2018-01-24T05:49:53Z | jimmy_foo@ctrl-c.club   | Welcome!
 | 2 | 2018-01-24T16:13:05Z | jerry_berry@ctrl-c.club | Suggestions for improv...
 | 3 | 2018-01-23T00:13:44Z | jimmy_foo@ctrl-c.club   | How do I spoo the fleem?
```

#### [r]eply
`reply #, r # - Reply to a specific topic`

Replies are responses to a specific topic -- they only appear when displaying the topic.

The line editor is quite basic.  Enter your message, line-by-line, and type a single period on a line by itself to end the message.

If you post an empty message, the system will discard it.

```
jennie_minnie@ctrl-c.club~> reply 3
Writing a reply to topic 'How do I spoo the fleem?'.  Type a period on a line by itself to end message.

reply~> Simple, you just boondoggle the flibbertigibbet.  That should be in the manual.
reply~> .
Reply saved!

jennie_minnie@ctrl-c.club~> 3

*** On 2018-01-23T00:13:44Z, jimmy_foo@ctrl-c.club posted...
---------------------------------------------------------------------------------
How do I spoo the fleem?
It's not in the docs and my boss is asking.  Any help is appreciated!
---------------------------------------------------------------------------------
=== On 2018-01-31T05:59:27Z, jennie_minnie@ctrl-c.club replied...
---------------------------------------------------------------------------------
Simple, you just boondoggle the flibbertigibbet.  That should be in the manual.
---------------------------------------------------------------------------------
```

#### [f]reshen
`freshen, f   - Reload to get any new messages`

This command reloads all users' message files to get any new messages that might have come in since you started the program.

#### reset OR clear
`reset, clear - Fix screen in case of text corruption`

This clears the screen and resets the cursor. If you experience screen corruption due to wide characters or terminal resizing, this may fix your visual issues.

#### [h]elp
`help, h, ?   - Display this text`

This displays helpful reminders of the commands that Iris supports.

### Serverless?  How does _that_ work?

`<IN PROGRESS>`

### Conventions

Iris leans heavily on convention.  Iris' security and message authentication is provided by filesystem permissions and message hashing.  Details can be found in #Technical Bits


#### Message Files

Each user has their own message file.  This contains all the messages that the user has written.  By convention it is named `iris.messages` and is located either in the user's home directory, or the user's directory in the shared message space:

`/home/jimmy_foo/.iris.messages`
`/var/iris/jimmy_foo/.iris.messages`

In order to operate correctly and safely, this file _must_ be:
* World-readable
* Owner-writable
* Non-executable
* Owned by the user account that will be storing messages for

```
%> ls -la ~/.iris.messages
-rw-r--r-- 1 jimmy_foo jimmy_foo /home/jimmy_foo/.iris.messages
```

### Technical Bits

`<IN PROGRESS>`

### License
GPLv2
