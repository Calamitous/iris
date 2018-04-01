#!/usr/bin/env ruby
require 'time'
require 'base64'
require 'digest'
require 'json'
require 'etc'
require 'readline'
# require 'pry' # Only needed for debugging

class String
  COLOR_MAP = {
    'n' => '0',
    'i' => '1',
    'u' => '4',
    'v' => '7',
    'r' => '31',
    'g' => '32',
    'y' => '33',
    'b' => '34',
    'm' => '35',
    'c' => '36',
    'w' => '37',
  }

  COLOR_RESET = "\033[0m"

  def color_token
    if self !~ /\w/
      return { '\{' => '|KOPEN|', '\}' => '|KCLOSE|', '}' => COLOR_RESET}[self]
    end

    tag = self.scan(/\w/).map{ |t| COLOR_MAP[t] }.sort.join(';')
    "\033[#{tag}m"
  end

  def colorize
    r = /\\{|{[rgybmcwniuv]+\s|\\}|}/
    split = self.split(r, 2)

    return self if r.match(self).nil?
    newstr = split.first + $&.color_token + split.last

    if r.match(newstr).nil?
      return (newstr + COLOR_RESET).gsub(/\|KOPEN\|/, '{').gsub(/\|KCLOSE\|/, '}')
    end

    newstr.colorize
  end

  def decolorize
    self.
      gsub(/\\{/, '|KOPEN|').
      gsub(/\\}/, '|KCLOSE|').
      gsub(/{[rgybmcwniuv]+\s|}/, '').
      gsub(/\|KOPEN\|/, '{').
      gsub(/\|KCLOSE\|/, '}')
  end

  def wrapped(width = Display::WIDTH)
    self.gsub(/.{1,#{width}}(?:\s|\Z|\-)/) {
      ($& + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")
    }
  end

  def pluralize(count)
    count == 1 ? self : self + 's'
  end
end

class Config
  VERSION      = '1.0.4'
  MESSAGE_FILE = "#{ENV['HOME']}/.iris.messages"
  HISTORY_FILE = "#{ENV['HOME']}/.iris.history"
  READ_FILE    = "#{ENV['HOME']}/.iris.read"
  IRIS_SCRIPT  = __FILE__

  USER         = ENV['USER'] || ENV['LOGNAME'] || ENV['USERNAME']
  HOSTNAME     = `hostname -d`.chomp
  AUTHOR       = "#{USER}@#{HOSTNAME}"

  def self.find_files
    (`ls /home/**/.iris.messages`).split("\n")
  end
end

class Corpus
  def self.load
    @@corpus    = Config.find_files.map { |filepath| IrisFile.load_messages(filepath) }.flatten.sort_by(&:timestamp)
    @@topics    = @@corpus.select{ |m| m.parent == nil }
    @@my_corpus = IrisFile.load_messages.sort_by(&:timestamp)
    @@my_reads  = IrisFile.load_reads
    @@all_hash_to_index = @@corpus.reduce({}) { |agg, msg| agg[msg.hash] = @@corpus.index(msg); agg }
    @@all_parent_hash_to_index = @@corpus.reduce({}) do |agg, msg|
      agg[msg.parent] ||= []
      agg[msg.parent] << @@corpus.index(msg)
      agg
    end
  end

  def self.to_json
    @@corpus.to_json
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

  def self.find_topic_by_id(topic_lookup)
    return nil unless topic_lookup
    index = topic_lookup.to_i - 1
    topics[index] if index >= 0 && index < topics.length
  end

  def self.find_topic_by_hash(topic_lookup)
    return nil unless topic_lookup
    find_message_by_hash(topic_lookup)
  end

  def self.read_hashes
    @@my_reads
  end

  def self.unread_messages
    @@corpus.reject{ |m| @@my_reads.include? m.hash }
  end

  def self.unread_topics
    @@topics.reject{ |m| @@my_reads.include? m.hash }
  end

  def self.size
    @@corpus.size
  end
end

class IrisFile
  def self.load_messages(filepath = Config::MESSAGE_FILE)
    # For logger: "Checking #{filepath}"
    return [] unless File.exists?(filepath)

    # For logger: "Found, parsing #{filepath}..."
    begin
      payload = JSON.parse(File.read(filepath))
    rescue JSON::ParserError => e
      if filepath == Config::MESSAGE_FILE
        Display.flowerbox(
          'Your message file appears to be corrupt.',
          "Could not parse valid JSON from #{filepath}",
          'Please fix or delete this message file to use Iris.')
        exit(1)
      else
        Display.say " * Unable to parse #{filepath}, skipping..."
        return []
      end
    end

    unless payload.is_a?(Array)
      if filepath == Config::MESSAGE_FILE
        Display.flowerbox(
          'Your message file appears to be corrupt.',
          "Could not interpret data from #{filepath}",
          '(It\'s not a JSON array of messages, as far as I can tell)',
          'Please fix or delete this message file to use Iris.')
        exit(1)
      else
        Display.say " * Unable to interpret data from #{filepath}, skipping..."
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

  def self.load_reads
    return [] unless File.exists? Config::READ_FILE

    begin
      read_array = JSON.parse(File.read(Config::READ_FILE))
    rescue JSON::ParserError => e
      Display.flowerbox(
        'Your read file appears to be corrupt.',
        "Could not parse valid JSON from #{Config::READ_FILE}",
        'Please fix or delete this read file to use Iris.')
      exit(1)
    end

    unless read_array.is_a?(Array)
      Display.flowerbox(
        'Your read file appears to be corrupt.',
        "Could not interpret data from #{Config::READ_FILE}",
        '(It\'s not a JSON array of message hashes, as far as I can tell)',
        'Please fix or delete this read file to use Iris.')
      exit(1)
    end

    read_array
  end

  def self.create_message_file
    raise 'Message file exists; refusing to overwrite!' if File.exists?(Config::MESSAGE_FILE)
    File.umask(0122)
    File.open(Config::MESSAGE_FILE, 'w') { |f| f.write('[]') }
  end

  def self.create_read_file
    raise 'Read file exists; refusing to overwrite!' if File.exists?(Config::READ_FILE)
    File.umask(0122)
    File.open(Config::READ_FILE, 'w') { |f| f.write('[]') }
  end

  def self.write_corpus(corpus)
    File.write(Config::MESSAGE_FILE, corpus)
  end

  def self.write_read_file(new_read_hashes)
    File.write(Config::READ_FILE, new_read_hashes)
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

  def topic?
    parent.nil?
  end

  def save!
    new_corpus = Corpus.mine << self
    IrisFile.write_corpus(JSON.pretty_generate(new_corpus))
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
    return stub.colorize if stub.decolorize.length <= length
    # colorize the stub, then decolorize to strip out any partial tags
    stub.colorize.slice(0, length - 6).decolorize + '...'
  end

  def latest_topic_timestamp
    (replies.map(&:timestamp).max || timestamp).gsub(/T/, ' ').gsub(/Z/, '')
  end

  def to_topic_line(index)
    error_marker = valid? ? '|' : 'X'
    head = [Display.print_index(index), latest_topic_timestamp, Display.print_author(author)].join(' | ')
    message_stub = truncated_message(Display::WIDTH - head.decolorize.length - 1)
    error_marker + ' ' + [head, message_stub].join(' | ')
  end

  def to_display
    error_marker =   valid? ? nil : '### THIS MESSAGE HAS THE FOLLOWING ERRORS ###'
    error_follower = valid? ? nil : '### THIS MESSAGE MAY BE CORRUPT OR TAMPERED WITH ###'

    bar = indent_text + ('-' * (Display::WIDTH - indent_text.decolorize.length))
    message_text = message.wrapped(Display::WIDTH - (indent_text.decolorize.length + 1)).split("\n").map{|m| indent_text + m }.join("\n")
    [
      '',
      "#{leader_text} On #{timestamp}, #{author} #{verb_text}...",
      error_marker,
      errors,
      error_follower,
      bar,
      message_text,
      bar
    ].flatten.compact.join("\n")
  end

  def to_topic_display
    [to_display] + replies.map(&:to_display)
  end

  def to_json(*args)
    {
      hash: hash,
      edit_hash: edit_hash,
      data: unconfirmed_payload
    }.to_json
  end

  def replies
    Corpus.find_all_by_parent_hash(hash)
  end

  private

  def leader_text
    topic? ? '***' : '    === REPLY==='
  end

  def verb_text
    topic? ? 'posted' : 'replied'
  end

  def indent_text
    topic? ? '' : '    | '
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

  def self.flowerbox(*lines, box_character: '*', box_thickness: 1)
    box_thickness.times do say box_character * WIDTH end
    lines.each { |line| say line }
    box_thickness.times do say box_character * WIDTH end
  end

  def self.say(stuff = '')
    stuff = stuff.join("\n") if stuff.is_a? Array
    puts stuff.colorize
  end

  def self.topic_index_width
    Corpus.topics.size.to_s.length
  end

  def self.topic_author_width
    Corpus.topics.map(&:author).map(&:length).max || 1
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
  ONE_SHOTS = %w{help topics compose quit freshen reset_display reply info}
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
    'reset'   => 'reset_display',
    'clear'   => 'reset_display',
    'i'       => 'info',
    'info  '  => 'info',
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
    Display.say 'Unrecognized command.  Type "help" for a list of available commands.'
  end

  def reset_display
    Display.say `tput reset`.chomp
  end

  def self.info
    Display.flowerbox(
      "Iris #{Config::VERSION}",
      "#{Corpus.topics.size} #{'topic'.pluralize(Corpus.topics.size)}, #{Corpus.unread_topics.size} unread.",
      "#{Corpus.size} #{'message'.pluralize(Corpus.size)}, #{Corpus.unread_messages.size} unread.",
      "#{Corpus.all.map(&:author).uniq.size} authors.",
        box_thickness: 0)
  end

  def info
    Display.say
    Interface.info
    Display.say
  end

  def reply(topic_id = nil)
    topic_id ||= @reply_topic
    unless topic_id
      Display.say "I can't reply to nothing! Include a topic ID or view a topic to reply to."
      return
    end

    if parent = Corpus.find_topic_by_id(topic_id)
      @reply_topic = parent.hash
    else
      Display.say "Could not reply; unable to find a topic with ID '#{topic_id}'"
      return
    end

    @mode = :replying
    @text_buffer = ''
    title = Corpus.find_topic_by_hash(parent.hash).truncated_message(Display::WIDTH - 26)
    Display.say
    Display.say "Writing a reply to topic '#{title}'"
    Display.say 'Type a period on a line by itself to end message.'
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
      Display.say 'Empty message, discarding...'
    else
      Message.new(@text_buffer, @reply_topic).save!
      Display.say 'Reply saved!'
    end
    @reply_topic = nil
    @mode = :browsing
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
      Display.say 'Empty message, discarding...'
    else
      Message.new(@text_buffer).save!
      Display.say 'Topic saved!'
    end
    @mode = :browsing
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

      Display.say msg.to_topic_display
      Display.say

      new_reads = (Corpus.read_hashes + [msg.hash] + msg.replies.map(&:hash)).uniq.sort
      IrisFile.write_read_file(new_reads.to_json)
      Corpus.load
    else
      Display.say 'Could not find a topic with that ID'
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

    Display.say "Welcome to Iris v#{Config::VERSION}.  Type 'help' for a list of commands; Ctrl-D or 'quit' to leave."
    while line = readline(prompt) do
      handle(line)
    end
  end

  def compose
    @mode = :composing
    @text_buffer = ''
    Display.say 'Writing a new topic.  Type a period on a line by itself to end message.'
  end

  def topics
    Display.say
    Corpus.topics.each_with_index do |topic, index|
      Display.say topic.to_topic_line(index + 1)
    end
    Display.say
  end

  def help
    Display.flowerbox(
      "Iris v#{Config::VERSION} readline interface",
      '',
      'Commands',
      '========',
      'help, h, ?   - Display this text',
      'topics, t    - List all topics',
      '# (topic id) - Read specified topic',
      'compose, c   - Add a new topic',
      'reply #, r # - Reply to a specific topic',
      'freshen, f   - Reload to get any new messages',
      'reset, clear - Fix screen in case of text corruption',
      'info, i      - Display Iris version and message stats',
      box_character: '')
  end

  def freshen
    Corpus.load
    Display.say 'Reloaded!'
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
  def self.print_help
    Display.flowerbox(
      "Iris v#{Config::VERSION} command-line",
      '',
      'Usage',
      '========',
      "#{__FILE__} [options]",
      '',
      'Options',
      '========',
      '--help, -h        - Display this text.',
      '--version, -v     - Display the current version of Iris.',
      '--stats, -s       - Display Iris version and message stats.',
      '--interactive, -i - Enter interactive mode (default)',
      '--dump, -d        - Dump entire message corpus out.',
      '',
      'If no options are provided, Iris will enter interactive mode.',
      box_character: '')
  end

  def self.start(args)
    if (args & %w{-v --version}).any?
      Display.say "Iris #{Config::VERSION}"
      exit(0)
    end

    if (args & %w{-h --help}).any?
      print_help
      exit(0)
    end

    if (args & %w{-s --stats}).any?
      Corpus.load
      Interface.info
      exit(0)
    end

    if (args & %w{-d --dump}).any?
      Corpus.load
      puts Corpus.to_json
      exit(0)
    end

    Display.say "Unrecognized option(s) #{args.join(', ')}"
    Display.say "Try -h for help"
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
      Display.say "You don't have a message file at #{Config::MESSAGE_FILE}."
      response = Readline.readline 'Would you like me to create it for you? (y/n) ', true

      if /[Yy]/ =~ response
        IrisFile.create_message_file
      else
        Display.say 'Cannot run Iris without a message file!'
        exit(1)
      end
    end

    IrisFile.create_read_file unless File.exists?(Config::READ_FILE)

    if File.stat(Config::MESSAGE_FILE).mode != 33188
      Display.flowerbox(
        'Your message file has incorrect permissions!  Should be "-rw-r--r--".',
        'You can change this from the command line with:',
        "  chmod 644 #{Config::MESSAGE_FILE}",
        'Leaving your file with incorrect permissions could allow unauthorized edits!')
    end

    if File.stat(Config::READ_FILE).mode != 33188
      Display.flowerbox(
        'Your read file has incorrect permissions!  Should be "-rw-r--r--".',
        'You can change this from the command line with:',
        "  chmod 644 #{Config::READ_FILE}")
    end

    if File.stat(Config::IRIS_SCRIPT).mode != 33261
      Display.flowerbox(
        'The Iris file has incorrect permissions!  Should be "-rwxr-xr-x".',
        'You can change this from the command line with:',
        "  chmod 755 #{__FILE__}",
        'If this file has the wrong permissions the program may be tampered with!')
    end
  end
end

Startupper.new(ARGV) if __FILE__==$0

