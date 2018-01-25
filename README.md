# Iris
## Serverless text-based forum for tilde-likes

### Installation

At its core, Iris is simply a single, executable Ruby script.  It has been tested and is known to work with Ruby 2.3.5.  No extra gems or libraries are required.

Copy or symlink `iris.rb` somewhere the whole server can use it; `/usr/local/bin` is a good candidate:

`chmod 555 ./iris.rb`
`mv ./iris.rb /usr/local/bin/iris`

As a convenience to users, you may also want to set up a world-read/writeable directory for message files:

```
mkdir /var/iris
chmod 666 /var/iris
```

### Usage

Iris has a readline interface that can be used to navigate the message corpus.  It can also be used directly with parameters from the command line.

#### Command Line Example
```
%> iris --version
Iris version 1.0

%> iris --unread-count
There are 14 unread messages.
You have 2 unread replies.
```

#### Readline Interface Example
```
%> iris
Welcome to Iris v. 1.0.0.  Type "help" for a list of commands.
jimmy_foo@ctrl-c.club> list
```

### Serverless?  How does _that_ work?

### Conventions

Iris leans heavily on convention. While many parts are configurable, it's best to stick as close to convention as possible-- this will ease administration, minimize security risks, and limit odd issues.

Iris' security and message authentication is provided by filesystem permissions and message hashing.  Details can be found in #Technical Bits


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

Alternatively, if you do not want to provide read access to a file in your home directory and your system administrator has set up a common directory, you can use that instead.  The same requirements apply:

```
%> ls -la /var/iris/jimmy_foo/.iris.messages
-rw-r--r-- 1 jimmy_foo jimmy_foo /var/iris/jimmy_foo/.iris.messages
```

#### User Configuration

User configuration is stored in the user's home directory, named `iris.config`.  Although carefully considered permissions are recommended, nothing is required except that it be readable by the user.

`/home/jimmy_foo/.iris.config`

#### Read Log

The read log keeps track of what messages the user has seen/read.  It is storedf in the user's home directory and named `iris.readlog`.

`/home/jimmy_foo/.iris.readlog`

The readlog must be owner read/writeable.

```
%> ls -la ~/.iris.readlog
-rw------- 1 jimmy_foo jimmy_foo /home/jimmy_foo/.iris.readlog
```

### Technical Bits

### License

