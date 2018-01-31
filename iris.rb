#!/usr/bin/env ruby

#  MVP:
# -----
# TODO: Create message file for current user if it doesn't exist
# TODO: Remove user config?
# TODO: Validate author with file owner
# TODO: Add optional title for topics
# TODO: Don't crash when names are cattywumpus
# TODO: Gracefully handle non-json files when/before parsing
# TODO: Gracefully validate message hashes on load
#
# Reading/Status:
# TODO: Add "read" list
# TODO: Add read/unread count
# TODO: Create read file for current user if it doesn't exist
# TODO: CLI options for scripting
#
# Tech debt:
# TODO: Split helptext into separate file?
# TODO: Move all puts into Display class
# TODO: Make all output WIDTH-aware
# TODO: Create struct to firm up message payload
# TODO: Common message file location for the security-conscious?
# TODO: Parse and manage options before instantiating Interface from .start
# TODO: Validate config, read, and history perms on startup
#
# Fancify interface:
# TODO: Use ENV for rows and cols of display?
# TODO: Pagination?
# TODO: Make nicer topic display
#
# Features:
# TODO: Add user muting
# TODO: Add .mute.iris support?
# TODO: Message deletion
# TODO: Add startup enviro health check
# TODO: Add message editing
# TODO: Add full message corpus dump for backup/debugging
#
# Later/Maybe:
# * ncurses client
# * customizable prompt
# * MOTD
# * Add to default startup script to display read count

require 'time'
require 'base64'
require 'digest'
require 'json'
require 'etc'
require 'readline'

class Config
  VERSION      = '1.0.0'
  CONFIG_FILE  = "#{ENV['HOME']}/.iris.config.json"
  MESSAGE_FILE = "#{ENV['HOME']}/.iris.messages"
  HISTORY_FILE = "#{ENV['HOME']}/.iris.history"

  USER         = ENV['USER'] || ENV['LOGNAME'] || ENV['USERNAME']
  HOSTNAME     = `hostname -d`.chomp
  AUTHOR       = "#{USER}@#{HOSTNAME}"

  def self.get(filepath = CONFIG_FILE)
    return @@loaded_config if @@loaded_config
    if !File.exists?(filepath)
      File.write(filepath, '{}')
      return @@loaded_config = {}
    end
    return @@loaded_config = JSON.load(filepath)
  end

  def self.find_files
    @@message_corpus ||= (`ls /home/**/.iris.messages`).split("\n")
  end
end

class IrisFile
  def self.load_messages(filepath = Config::MESSAGE_FILE)
    # For logger: puts "Checking #{filepath}"
    return [] unless File.exists?(filepath)

    # For logger: puts "Found, parsing #{filepath}..."
    payload = JSON.parse(File.read(filepath))
    raise 'Invalid File!' unless payload.is_a?(Array)

    uid = File.stat(filepath).uid
    username = Etc.getpwuid(uid).name

    payload.map do |message_json|
      new_message = Message.load(message_json)
      new_message.validate_user(username)
      new_message
    end
  end

  def self.write_corpus(corpus)
    File.write(Config::MESSAGE_FILE, corpus)
  end
end

class Corpus
  def self.load
    @@corpus    = Config.find_files.map { |filepath| IrisFile.load_messages(filepath) }.flatten.sort_by(&:timestamp)
    @@topics    = @@corpus.select{ |m| m.parent == nil }
    @@my_corpus = IrisFile.load_messages.sort_by(&:timestamp)
  end

  def self.all
    @@corpus
  end

  def self.topics
    @@topics
  end

  def self.mine
    @@my_corpus
  end
end

class Message
  FILE_FORMAT = 'v2'

  attr_reader :timestamp, :hash, :edit_hash, :author, :parent, :message, :errors

  def initialize(message, author = Config::AUTHOR, parent = nil, timestamp = Time.now.utc.iso8601, edit_hash = nil)
    @parent    = parent
    @author    = author
    @timestamp = timestamp
    @message   = message
    @errors    = []
  end

  def self.load(payload)
    data = payload if payload.is_a?(Hash)
    data = JSON.parse(payload) if payload.is_a?(String)

    loaded_message = self.new(data['data']['message'], data['data']['author'], data['data']['parent'], data['data']['timestamp'], data['edit_hash'])
    loaded_message.validate_hash(data['hash'])
    loaded_message
  end

  def validate_user(username)
    @errors << 'Unvalidatable; could not parse username' if username.nil?
    @errors << 'Unvalidatable; username is empty' if username.empty?

    user_regex = Regexp.new("(.*)@#{Config::HOSTNAME}$")
    author_name = user_regex.match(author)[1]
    @errors << "Bad username: got #{author}'s message from #{username}'s message file." unless author_name == username
  end

  def validate_hash(test_hash)
    if hash != test_hash
      @errors << "Broken hash: expected '#{hash}', got '#{test_hash}'"
    end
  end

  def valid?
    @errors.empty?
  end

  def save!
    new_corpus = Corpus.mine << self
    IrisFile.write_corpus(new_corpus.to_json)
    Corpus.load
  end

  def hash(payload = nil)
    payload ||= unconfirmed_payload.to_json
    Base64.encode64(Digest::SHA1.digest(payload))
  end

  def truncated_message(length)
    stub = message.split("\n").first
    return stub if stub.length <= length
    stub.slice(0, length - 3) + '...'
  end

  def to_topic_line(index)
    head = ['', Display.print_index(index), timestamp, author].join(' | ')
    message_stub = truncated_message(Display::WIDTH - head.length)
    [head, message_stub].join(' | ')
  end

  def to_topic_display
    [
      "On #{timestamp}, #{author} posted...",
      '-' * Display::WIDTH,
      message,
      '-' * Display::WIDTH
    ].join("\n")
  end

  def is_topic?
    parent.nil?
  end

  def to_json(*args)
    {
      hash: hash,
      edit_hash: edit_hash,
      data: unconfirmed_payload
    }.to_json
  end

  def unconfirmed_payload
    {
      author: author,
      parent: parent,
      timestamp: timestamp,
      message: message,
    }
  end
end

class Display
  WIDTH = 80

  def self.topic_index_width
    Corpus.topics.size.to_s.length
  end

  def self.print_index(index)
    ((' ' * topic_index_width) + index.to_s)[(-topic_index_width)..-1]
  end
end

class Interface
  ONE_SHOTS = %w{help topics create quit freshen}
  CMD_MAP = {
    't'       => 'topics',
    'topics'  => 'topics',
    'c'       => 'create',
    'create'  => 'create',
    'h'       => 'help',
    '?'       => 'help',
    'help'    => 'help',
    'r'       => 'reply',
    'reply'   => 'reply',
    'q'       => 'quit',
    'quit'    => 'quit',
    'freshen' => 'freshen',
    'f'       => 'freshen',
  }

  def browsing_handler(line)
    cmd = line.split(/\s/).first
    cmd = CMD_MAP[cmd] || cmd
    return self.send(cmd.to_sym) if ONE_SHOTS.include?(cmd)
    return show_topic(cmd) if cmd =~ /^\d+$/
  end

  def creating_handler(line)
    if line !~ /^\.$/
      if @text_buffer.empty?
        @text_buffer = line
      else
        @text_buffer = [@text_buffer, line].join("\n")
      end
      return
    end

    if @text_buffer.length <= 1
      puts 'Empty message, discarding...'
    else
      Message.new(@text_buffer).save!
      puts 'Topic saved!'
    end
    @mode = :browsing
  end

  def handle(line)
    return browsing_handler(line) if @mode == :browsing
    return creating_handler(line) if @mode == :creating
  end

  def show_topic(num)
    index = num.to_i - 1
    if index >= 0 && index < Corpus.topics.length
      puts Corpus.topics[index].to_topic_display
    else
      puts 'Could not find a topic with that ID'
    end
  end

  def quit
    exit(0)
  end

  def self.start(args)
    self.new(args)
  end

  def prompt
    return 'new~> ' if @mode == :creating
    return 'reply~> ' if @mode == :replying
    "#{Config::AUTHOR}~> "
  end

  def initialize(args)
    Corpus.load
    @history_loaded = false
    @mode = :browsing

    puts "Welcome to Iris v#{Config::VERSION}.  Type 'help' for a list of commands; Ctrl-D or 'quit' to leave."
    while line = readline(prompt) do
      puts handle(line)
    end
  end

  def create
    @mode = :creating
    @text_buffer = ''
    puts 'Writing a new topic.  Type a period on a line by itself to end.'
  end

  def topics
    Corpus.topics.each_with_index { |topic, index| puts topic.to_topic_line(index + 1) }
    nil
  end

  def help
    puts
    puts "Iris v#{Config::VERSION}"
    puts
    puts 'Commands'
    puts '========'
    puts 'help, h, ?   - Display this text'
    puts 'topics, t    - List all topics'
    puts '# (topic id) - Read specified topic'
    puts 'create, c    - Add a new topic'
    puts 'reply #, r # - Reply to a specific topic'
    puts 'freshen, f   - Reload to get any new messages'
    puts
  end

  def freshen
    Corpus.load
    puts 'Reloaded!'
  end

  def readline(prompt)
    if !@history_loaded && File.exist?(Config::HISTORY_FILE)
      @history_loaded = true
      if File.readable?(Config::HISTORY_FILE)
        File.readlines(Config::HISTORY_FILE).each {|l| Readline::HISTORY.push(l.chomp)}
      end
    end

    if line = Readline.readline(prompt, true)
      if File.writable?(Config::HISTORY_FILE)
        File.open(Config::HISTORY_FILE) {|f| f.write(line+"\n")}
      end
      return line
    else
      return nil
    end
  end
end

class CLI
  def self.start(args)
  end
end

class Startupper
  def initialize(args)
    perform_startup_checks

    if (args & %w{-i --interactive}).any? || args.empty?
      Interface.start(args)
    else
      CLI.start(args)
    end
  end

  def perform_startup_checks
    if File.stat(Config::MESSAGE_FILE).mode != 33188
      puts '*' * 80
      puts 'Your message file has incorrect permissions!  Should be "-rw-r--r--".'
      puts 'You can change this from the command line with:'
      puts "  chmod 644 #{Config::MESSAGE_FILE}"
      puts 'Leaving your file with incorrect permissions could allow unauthorized edits!'
      puts '*' * 80
    end

    if File.stat(__FILE__).mode != 33261
      puts '*' * 80
      puts 'The Iris file has incorrect permissions!  Should be "-rwxr-xr-x".'
      puts 'You can change this from the command line with:'
      puts "  chmod 755 #{__FILE__}"
      puts 'If this file has the wrong permissions the program may be tampered with!'
      puts '*' * 80
    end
  end
end

Startupper.new(ARGV)
