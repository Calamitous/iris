#!/usr/bin/env ruby

#  MVP:
# -----
# TODO: Finish up README.md
#
# Reading/Status:
# TODO: Add "read" list
# TODO: Add read/unread count
# TODO: Create read file for current user if it doesn't exist
# TODO: CLI options for scripting
#
# Tech debt:
# TODO: Add tests
# TODO: Split helptext into separate file?
# TODO: Move all puts into Display class
# TODO: Make all output WIDTH-aware
# TODO: Create struct to firm up message payload
# TODO: Common message file location for the security-conscious?
# TODO: Parse and manage options before instantiating Interface from .start
# TODO: Validate config, read, and history perms on startup
# TODO: Let Message initialization accept params as a hash
#
# Fancify interface:
# TODO: Use ENV for rows and cols of display? (No)
# TODO: Pagination?
# TODO: Make nicer topic display
# TODO: Add optional title for topics
#
# Features:
# TODO: Add read-only mode if user doesn't want/can't have message file
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
  MESSAGE_FILE = "#{ENV['HOME']}/.iris.messages"
  HISTORY_FILE = "#{ENV['HOME']}/.iris.history"

  USER         = ENV['USER'] || ENV['LOGNAME'] || ENV['USERNAME']
  HOSTNAME     = `hostname -d`.chomp
  AUTHOR       = "#{USER}@#{HOSTNAME}"

  def self.find_files
    @@message_corpus ||= (`ls /home/**/.iris.messages`).split("\n")
  end
end

class IrisFile
  def self.load_messages(filepath = Config::MESSAGE_FILE)
    # For logger: puts "Checking #{filepath}"
    return [] unless File.exists?(filepath)

    # For logger: puts "Found, parsing #{filepath}..."
    begin
      payload = JSON.parse(File.read(filepath))
    rescue JSON::ParserError => e
      if filepath == Config::MESSAGE_FILE
        puts '*' * 80
        puts 'Your message file appears to be corrupt.'
        puts "Could not parse valid JSON from #{filepath}"
        puts 'Please fix or delete this message file to use Iris.'
        puts '*' * 80
        exit(0)
      else
        puts " * Unable to parse #{filepath}, skipping..."
        return []
      end
    end

    unless payload.is_a?(Array)
      if filepath == Config::MESSAGE_FILE
        puts '*' * 80
        puts 'Your message file appears to be corrupt.'
        puts "Could not interpret data from #{filepath}"
        puts '(It\'s not a JSON array of messages, as far as I can tell)'
        puts 'Please fix or delete this message file to use Iris.'
        puts '*' * 80
        exit(0)
      else
        puts " * Unable to interpret data from #{filepath}, skipping..."
        return []
      end
    end

    uid = File.stat(filepath).uid
    username = Etc.getpwuid(uid).name

    payload.map do |message_json|
      new_message = Message.load(message_json)
      new_message.validate_user(username)
      new_message
    end
  end

  def self.create_message_file
    raise 'File exists; refusing to overwrite!' if File.exists?(Config::MESSAGE_FILE)
    File.umask(0122)
    File.open(Config::MESSAGE_FILE, 'w') { |f| f.write('[]') }
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
    @@all_hash_to_index = @@corpus.reduce({}) { |agg, msg| agg[msg.hash] = @@corpus.index(msg); agg }
    @@all_parent_hash_to_index = @@corpus.reduce({}) do |agg, msg|
      agg[msg.parent] ||= []
      agg[msg.parent] << @@corpus.index(msg)
      agg
    end
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

  def self.find_message_by_hash(hash)
    return nil unless hash
    index = @@all_hash_to_index[hash]
    return nil unless index
    all[index]
  end

  def self.find_all_by_parent_hash(hash)
    return [] unless hash
    indexes = @@all_parent_hash_to_index[hash]
    return [] unless indexes
    indexes.map{ |idx| all[idx] }
  end

  def self.find_topic(topic_id)
    if topic_id.to_i == 0
      # This must be a hash, handle appropriately
      msg = find_message_by_hash(topic_id)
      puts 'WARNING: Expected a topic but got a reply!' unless msg.is_topic?
      msg
    else
      # This must be an index, handle appropriately
      index = topic_id.to_i - 1
      return topics[index] if index >= 0 && index < topics.length
    end
  end
end

class Message
  FILE_FORMAT = 'v2'

  attr_reader :timestamp, :edit_hash, :author, :parent, :message, :errors

  def initialize(message, parent = nil, author = Config::AUTHOR, timestamp = Time.now.utc.iso8601, edit_hash = nil)
    @parent    = parent
    @author    = author
    @timestamp = timestamp
    @message   = message
    @hash      = hash
    @errors    = []
  end

  def self.load(payload)
    data = payload if payload.is_a?(Hash)
    data = JSON.parse(payload) if payload.is_a?(String)

    loaded_message = self.new(data['data']['message'], data['data']['parent'], data['data']['author'], data['data']['timestamp'], data['edit_hash'])
    loaded_message.validate_hash(data['hash'])
    loaded_message
  end

  def validate_user(username)
    @errors << 'Unvalidatable; could not parse username' if username.nil?
    @errors << 'Unvalidatable; username is empty' if username.empty?

    user_regex = Regexp.new("(.*)@#{Config::HOSTNAME}$")
    author_match = user_regex.match(author)

    unless author_match && author_match[1] == username
      @errors << "Bad username: got #{author}'s message from #{username}'s message file."
    end
  end

  def validate_hash(test_hash)
    if self.hash != test_hash
      @errors << "Broken hash: expected '#{hash.chomp}', got '#{test_hash.chomp}'"
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
    if payload.nil?
      return @hash if @hash
      payload = unconfirmed_payload.to_json
    end
    Base64.encode64(Digest::SHA1.digest(payload))
  end

  def truncated_message(length)
    stub = message.split("\n").first
    return stub if stub.length <= length
    stub.slice(0, length - 6) + '...'
  end

  def to_topic_line(index)
    error_marker = valid? ? ' ' : 'X'
    head = [error_marker, Display.print_index(index), timestamp, Display.print_author(author)].join(' | ')
    message_stub = truncated_message(Display::WIDTH - head.length)
    [head, message_stub].join(' | ')
  end

  def leader_text
    is_topic? ? '***' : '==='
  end

  def verb_text
    is_topic? ? 'posted' : 'replied'
  end

  def to_display
    error_marker =   valid? ? nil : '### THIS MESSAGE HAS THE FOLLOWING ERRORS ###'
    error_follower = valid? ? nil : '### THIS MESSAGE MAY BE CORRUPT OR TAMPERED WITH ###'
    [
      "#{leader_text} On #{timestamp}, #{author} #{verb_text}...",
      error_marker,
      errors,
      error_follower,
      '-' * Display::WIDTH,
      message,
      '-' * Display::WIDTH
    ].flatten.compact.join("\n")
  end

  def to_topic_display
    [to_display] + replies.map(&:to_display)
  end

  def replies
    Corpus.find_all_by_parent_hash(hash)
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
  MIN_WIDTH = 80
  WIDTH = [ENV['COLUMNS'].to_i, `tput cols`.chomp.to_i, MIN_WIDTH].compact.max

  def self.topic_index_width
    Corpus.topics.size.to_s.length
  end

  def self.topic_author_width
    Corpus.topics.map(&:author).map(&:length).max
  end

  def self.print_index(index)
    # Left-align
    ((' ' * topic_index_width) + index.to_s)[(-topic_index_width)..-1]
  end

  def self.print_author(author)
    # Right-align
    (author.to_s + (' ' * topic_author_width))[0..(topic_author_width - 1)]
  end
end

class Interface
  ONE_SHOTS = %w{help topics compose quit freshen reply}
  CMD_MAP = {
    't'       => 'topics',
    'topics'  => 'topics',
    'c'       => 'compose',
    'compose' => 'compose',
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
    tokens = line.split(/\s/)
    cmd = tokens.first
    cmd = CMD_MAP[cmd] || cmd
    return self.send(cmd.to_sym) if ONE_SHOTS.include?(cmd) && tokens.length == 1
    return show_topic(cmd) if cmd =~ /^\d+$/
    # We must have args, let's handle 'em
    arg = tokens.last
    return reply(arg) if cmd == 'reply'
    puts 'Unrecognized command.  Type "help" for a list of available commands.'
    nil
  end

  def reply(topic_id = nil)
    topic_id ||= @reply_topic
    unless topic_id
      puts "I can't reply to nothing! Include a topic ID or view a topic to reply to."
      return
    end

    if parent = Corpus.find_topic(topic_id)
      @reply_topic = parent.hash
    else
      puts "Could not reply; unable to find a topic with ID '#{topic_id}'"
      return
    end

    @mode = :replying
    @text_buffer = ''
    title = Corpus.find_topic(parent.hash).truncated_message(80)
    puts "Writing a reply to topic '#{title}'.  Type a period on a line by itself to end message."
  end

  def replying_handler(line)
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
      Message.new(@text_buffer, @reply_topic).save!
      puts 'Reply saved!'
    end
    @reply_topic = nil
    @mode = :browsing
    nil
  end

  def composing_handler(line)
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
    nil
  end

  def handle(line)
    return browsing_handler(line)  if @mode == :browsing
    return composing_handler(line) if @mode == :composing
    return replying_handler(line)  if @mode == :replying
  end

  def show_topic(num)
    index = num.to_i - 1
    if index >= 0 && index < Corpus.topics.length
      msg = Corpus.topics[index]
      @reply_topic = msg.hash
      puts msg.to_topic_display
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
    return 'new~> ' if @mode == :composing
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

  def compose
    @mode = :composing
    @text_buffer = ''
    puts 'Writing a new topic.  Type a period on a line by itself to end message.'
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
    puts 'compose, c    - Add a new topic'
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
    unless File.exists?(Config::MESSAGE_FILE)
      puts "You don't have a message file at #{Config::MESSAGE_FILE}."
      response = Readline.readline 'Would you like me to create it for you? (y/n) ', true

      if /[Yy]/ =~ response
        IrisFile.create_message_file
      else
        puts 'Cannot run Iris without a message file!'
        exit(1)
      end
    end

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
