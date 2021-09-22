#!/usr/bin/env ruby
require 'base64'
require 'digest'
require 'etc'
require 'json'
require 'readline'
require 'time'
# require 'pry' # Only needed for debugging

class Config
  VERSION      = '1.0.13'
  MESSAGE_FILE = "#{ENV['HOME']}/.iris.messages"
  HISTORY_FILE = "#{ENV['HOME']}/.iris.history"
  IRIS_SCRIPT  = __FILE__

  USER         = ENV['USER'] || ENV['LOGNAME'] || ENV['USERNAME']
  HOSTNAME     = `hostname -d`.chomp
  AUTHOR       = "#{USER}@#{HOSTNAME}"
  OPTIONS      = %w[
    --debug
    --dump
    --help
    --interactive
    --mark-all-read
    --stats
    --test-file
    --version
    -d
    -f
    -h
    -i
    -p
    -s
    -v
  ]
  INTERACTIVE_OPTIONS    = %w[-i --interactive]
  NONINTERACTIVE_OPTIONS = %w[-d --dump -h --help -v --version -s --stats --mark-all-read]
  NONFILE_OPTIONS        = %w[-h --help -v --version]

  @@debug_mode = false

  def self.find_files
    (`ls /home/**/.iris.messages`).split("\n")
  end

  def self.messagefile_filename
    $test_corpus_file || Config::MESSAGE_FILE
  end

  def self.readfile_filename
    "#{messagefile_filename}.read"
  end

  def self.historyfile_filename
    "#{messagefile_filename}.history"
  end

  def self.enable_debug_mode
    @@debug_mode = true
  end

  def self.debug?
    @@debug_mode
  end
end

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

    return self.color_bounded if r.match(self).nil?
    newstr = split.first + $&.color_token + split.last

    if r.match(newstr).nil?
      return (newstr + COLOR_RESET).gsub(/\|KOPEN\|/, '{').gsub(/\|KCLOSE\|/, '}').color_bounded
    end

    newstr.colorize.color_bounded
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

  def color_bounded
    COLOR_RESET + self.gsub(/\n/, "\n#{COLOR_RESET}") + COLOR_RESET
  end
end

class Corpus
  def self.load
    if $test_corpus_file
      @@corpus = IrisFile.load_messages
    else
      @@corpus = Config.find_files.map { |filepath| IrisFile.load_messages(filepath) }.flatten.sort_by(&:timestamp)
    end

    @@my_corpus = IrisFile.load_messages.sort_by(&:timestamp)
    @@my_reads  = IrisFile.load_reads

    @@unread_messages = nil

    @@all_hash_to_index = @@corpus.reduce({}) { |agg, msg| agg[msg.hash] = @@corpus.index(msg); agg }
    @@edited_hashes     = @@corpus.map(&:edit_hash).compact
    @@topics            = @@corpus.select(&:is_topic?)

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

  def self.edited_hashes
    @@edited_hashes
  end

  def self.topics
    @@topics
  end

  def self.mine
    @@my_corpus
  end

  def self.is_mine?(message)
    @@my_corpus.map(&:hash).include? message.hash
  end

  def self.is_topic?(message)
    @@topics.map(&:hash).include? message.hash
  end

  def self.index_of(message)
    @@corpus.map(&:hash).index message.hash
  end

  def self.topic_index_of(message)
    @@topics.map(&:hash).index message.hash
  end

  def self.find_message_by_hash(hash)
    return nil unless hash
    index = @@all_hash_to_index[hash]
    return nil unless index
    all[index]
  end

  def self.has_edit_hash(hash)
    return nil unless hash
    Corpus.all.map(&:edit_hash).include?(hash)
  end

  def self.find_all_by_parent_hash(hash)
    return [] unless hash
    indexes = @@all_parent_hash_to_index[hash]
    return [] unless indexes
    indexes.map{ |idx| all[idx] }.compact.select(&:show_me?)
  end

  def self.find_topic_by_id(topic_lookup)
    return nil unless topic_lookup
    index = topic_lookup.to_i - 1
    topics[index] if index >= 0 && index < topics.length
  end

  def self.find_message_by_id(message_lookup)
    return nil unless message_lookup && message_lookup =~ /\AM\d+\Z/
    index = message_lookup.gsub(/M/, '').to_i - 1
    @@corpus[index] if index >= 0 && index < @@corpus.length
  end

  def self.find_topic_by_hash(topic_lookup)
    return nil unless topic_lookup
    find_message_by_hash(topic_lookup)
  end

  def self.read_hashes
    @@my_reads
  end

  def self.unread_messages
    @@unread_messages ||= @@corpus
      .select { |message| message.show_me? }
      .reject{ |m| @@my_reads.include? m.hash }
      .reject{ |m| @@my_corpus.map(&:hash).include? m.hash }
  end

  def self.unread_message_hashes
    self.unread_messages.map(&:hash)
  end

  def self.unread_topics
    @@topics.select do |m|
      # Is the topic unread, or are any of its displayable replies unread?
      m.unread? ||
        find_all_by_parent_hash(m.hash).reduce(false) { |agg, r| agg || r.unread? }
    end
  end

  def self.size
    @@corpus.size
  end

  def self.mark_as_read(hashes)
    new_reads = (Corpus.read_hashes + hashes).uniq.sort
    IrisFile.write_read_file(new_reads.to_json)
    Corpus.load
  end
end

class IrisFile
  def self.load_messages(filepath = nil)
    if filepath.nil?
      filepath = Config.messagefile_filename
    end

    return [] unless File.exists?(filepath)

    begin
      payload = JSON.parse(File.read(filepath))
    rescue JSON::ParserError => e
      if filepath == Config.messagefile_filename
        Display.flowerbox(
          'Your message file appears to be corrupt.',
          "Could not parse valid JSON from #{filepath}",
          'Please fix or delete this message file to use Iris.')
        exit(1)
      else
        Display.say " * Unable to parse #{filepath}, skipping..."
        return []
      end
    rescue Errno::EACCES => e
      Display.warn " * Unable to read data from #{filepath}, permission denied.  Skipping..."
      return []
    end

    unless payload.is_a?(Array)
      if filepath == Config.messagefile_filename
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

    begin
      username = Etc.getpwuid(uid).name
    rescue ArgumentError
      Display.warn("'#{filepath}' does not appear to have a valid UID in /etc/passwd, skipping...")
      return []
    end

    payload.map do |message_json|
      new_message = Message.load(message_json)
      new_message.validate_user(username)
      new_message
    end
  end

  def self.load_reads
    return [] unless File.exists? Config.readfile_filename

    begin
      read_array = JSON.parse(File.read(Config.readfile_filename))
    rescue JSON::ParserError => e
      Display.flowerbox(
        'Your read file appears to be corrupt.',
        "Could not parse valid JSON from #{Config.readfile_filename}",
        'Please fix or delete this read file to use Iris.')
      exit(1)
    end

    unless read_array.is_a?(Array)
      Display.flowerbox(
        'Your read file appears to be corrupt.',
        "Could not interpret data from #{Config.readfile_filename}",
        '(It\'s not a JSON array of message hashes, as far as I can tell)',
        'Please fix or delete this read file to use Iris.')
      exit(1)
    end

    read_array
  end

  def self.create_message_file
    raise 'Should not try to create message file in test mode!' if $test_corpus_file
    raise 'Message file exists; refusing to overwrite!' if File.exists?(Config::MESSAGE_FILE)
    File.umask(0122)
    File.open(Config::MESSAGE_FILE, 'w') { |f| f.write('[]') }
  end

  def self.create_read_file
    return if File.exists?(Config.readfile_filename)

    File.umask(0122)
    File.open(Config.readfile_filename, 'w') { |f| f.write('[]') }
  end

  def self.write_corpus(corpus)
    File.write(Config.messagefile_filename, corpus)
  end

  def self.write_read_file(new_read_hashes)
    if $test_corpus_file
      File.write("#{$test_corpus_file}.read", new_read_hashes)
    else
      File.write(Config.readfile_filename, new_read_hashes)
    end
  end
end

class Message
  FILE_FORMAT = 'v2'

  attr_reader :timestamp, :edit_hash, :author, :parent, :message, :errors, :is_deleted

  def initialize(message, parent = nil, author = Config::AUTHOR, edit_hash = nil, timestamp = Time.now.utc.iso8601, is_deleted = nil)
    @message    = message
    @parent     = parent
    @author     = author
    @edit_hash  = edit_hash
    @timestamp  = timestamp
    @hash       = hash
    @is_deleted = is_deleted
    @errors     = []
  end

  def self.load(payload)
    data = payload if payload.is_a?(Hash)
    data = JSON.parse(payload) if payload.is_a?(String)

    loaded_message = self.new(data['data']['message'], data['data']['parent'], data['data']['author'], data['edit_hash'], data['data']['timestamp'], data['is_deleted'])
    loaded_message.validate_hash(data['hash'])
    loaded_message
  end

  def self.edit(new_text, old_message)
    Message.new(new_text, old_message.parent, old_message.author, old_message.hash, old_message.timestamp).save!
  end

  def is_topic?
    parent.nil? && show_me?
  end

  def delete
    @is_deleted = !@is_deleted
    replace!
  end

  def edited?
    !(edit_hash.nil? || edit_hash.empty?)
  end

  # Only show messages that don't have a following, edited message
  def show_me?
    !Corpus.edited_hashes.include?(hash)
  end

  def validate_user(username)
    @errors << 'Unvalidatable; could not parse username' if username.nil?
    @errors << 'Unvalidatable; username is empty' if username.empty?

    user_regex = Regexp.new("(.*)@.*$")
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

  def replace!
    new_corpus = Corpus.mine.reject { |message| message.hash == self.hash } << self
    IrisFile.write_corpus(JSON.pretty_generate(new_corpus))
    Corpus.load
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

  def truncated_display_message(length)
    if is_deleted
      stub = '{r TOPIC DELETED BY AUTHOR}'
    else
      stub = message.split("\n").first
    end
    return stub.colorize if stub.decolorize.length <= length
    # Colorize the stub, then decolorize to strip out any partial tags
    stub.colorize.slice(0, length - 5 - Display.topic_index_width).decolorize + '...'
  end

  def truncated_message(length)
    stub = message.split("\n").first
    return stub.colorize if stub.decolorize.length <= length
    # Colorize the stub, then decolorize to strip out any partial tags
    stub.colorize.slice(0, length - 5 - Display.topic_index_width).decolorize + '...'
  end

  def latest_topic_timestamp
    (replies.map(&:timestamp).max || timestamp || 'UNKNOWN').gsub(/T/, ' ').gsub(/Z/, '')
  end

  def unread?
    Corpus.unread_messages.include? self
  end

  def topic_status
    return '{r X}' unless valid?
    unread_count = replies.count(&:unread?)
    unread_count += 1 if self.unread?
    return ' ' if unread_count == 0
    return '*' if unread_count > 9
    unread_count.to_s
  end

  def to_topic_line(index)
    head = [Display.print_index(index), topic_status, latest_topic_timestamp, Display.print_author(author)].join(' | ')
    message_stub = truncated_display_message(Display::WIDTH - head.decolorize.length - 1)
    '| ' + [head, message_stub].join(' | ')
  end

  def to_display
    error_marker =   valid? ? nil : '{r ### THIS MESSAGE HAS THE FOLLOWING ERRORS ###}'
    error_follower = valid? ? nil : '{r ### THIS MESSAGE MAY BE CORRUPT OR MAY HAVE BEEN TAMPERED WITH ###}'

    message_header = "#{leader_text} On #{timestamp}, #{author} #{verb_text}..."

    header_bar = (indent_text + message_header + ('-' * (Display::WIDTH)))
    header_offset = header_bar.length - header_bar.decolorize.length
    header_bar = header_bar[0..Display::WIDTH + header_offset - 1]

    bar = indent_text + ('-' * (Display::WIDTH - indent_text.decolorize.length))

    if @is_deleted
      message_text = nil
    else
      message_text = message.wrapped(Display::WIDTH - (indent_text.decolorize.length + 1)).split("\n").map{|m| indent_text + m }.join("\n")
    end

    [
      '',
      error_marker,
      errors,
      error_follower,
      header_bar,
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
      is_deleted: is_deleted,
      data: unconfirmed_payload
    }.to_json
  end

  def edit_predecessor
    return nil unless edit_hash
    Corpus.find_message_by_hash(edit_hash)
  end

  # Find all messages replying to the current topic, including replies to topics
  # which have been edited.
  def replies
    all_replies = Corpus.find_all_by_parent_hash(hash)
    all_replies += ((edit_predecessor && edit_predecessor.replies) || [])
    all_replies.compact.sort_by{ |reply| Corpus.index_of(reply) }
  end

  def id
    'M' + (Corpus.index_of(self) + 1).to_s
  end

  def topic_id
    return nil unless Corpus.is_topic?(self)
    Corpus.topic_index_of(self) + 1
  end

  private

  def status_flag
    return '{r (deleted)}' if @is_deleted
    '{y (edited)}' if edited?
  end

  def leader_text
    topic? ? "{g ***} [#{topic_id}] #{status_flag}" : ["{g ===}", "[#{id}]", status_flag].compact.join(' ')
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
  MIN_HEIGHT = 8

  WIDTH = [ENV['COLUMNS'].to_i, `tput cols`.chomp.to_i, MIN_WIDTH].compact.max
  HEIGHT = [ENV['ROWS'].to_i, `tput lines`.chomp.to_i, MIN_HEIGHT].compact.max

  # p Readline.get_screen_size
  # WIDTH = Readline.get_screen_size[1]
  TITLE_WIDTH = WIDTH - 26

  def self.permissions_error(filename, file_description, permission_string, mode_string, consequence = nil)
    message = [
      "Your #{file_description} file has incorrect permissions!  Should be \"#{permission_string}\".",
      "You can change this from the command line with:",
      "  chmod #{mode_string} #{filename}",
      consequence
    ].compact
    self.flowerbox(message)
  end

  def self.flowerbox(*lines, box_character: '*', box_thickness: 1)
    box_thickness.times do say box_character * WIDTH end
    lines.each { |line| say line }
    box_thickness.times do say box_character * WIDTH end
  end

  def self.say(stuff = '')
    stuff = stuff.join("\n") if stuff.is_a? Array
    puts stuff.colorize
  end

  def self.warn(stuff = '')
    say("{y WARNING: }#{stuff}") if Config.debug?
  end

  def self.topic_index_width
    [Corpus.topics.size.to_s.length, 2].max
  end

  def self.topic_author_width
    Corpus.topics.map(&:author).map(&:length).max || 1
  end

  def self.print_index(index)
    # Left-align
    '{w ' + ((' ' * topic_index_width) + index.to_s)[(-topic_index_width)..-1] + '}'
  end

  def self.print_author(author)
    # Right-align
    (author.to_s + (' ' * topic_author_width))[0..(topic_author_width - 1)]
  end

  def self.topic_header
    author_head = ('AUTHOR' + (' ' * WIDTH))[0..topic_author_width-1]
    '| ' + ['ID', 'U', 'TIMESTAMP          ', author_head, 'TITLE'].join(' | ')
  end
end

class Interface
  ONE_SHOTS = %w{ compose delete edit freshen help info mark_all_read mark_read next quit reply reset_display topics unread }
  CMD_MAP = {
    '?'              => 'help',
    'c'              => 'compose',
    'clear'          => 'reset_display',
    'compose'        => 'compose',
    'd'              => 'delete',
    'delete'         => 'delete',
    'e'              => 'edit',
    'edit'           => 'edit',
    'f'              => 'freshen',
    'freshen'        => 'freshen',
    'h'              => 'help',
    'help'           => 'help',
    'i'              => 'info',
    'info  '         => 'info',
    'm'              => 'mark_read',
    'mark'           => 'mark_read',
    'mark_all_read'  => 'mark_all_read',
    'n'              => 'next',
    'next'           => 'next',
    'q'              => 'quit',
    'quit'           => 'quit',
    'r'              => 'reply',
    'reply'          => 'reply',
    'reset'          => 'reset_display',
    't'              => 'topics',
    'topics'         => 'topics',
    'u'              => 'unread',
    'undelete'       => 'delete',
    'unread'         => 'unread',
  }

  def browsing_handler(line)
    tokens = line.split(/\s/)
    cmd = tokens.first
    cmd = CMD_MAP[cmd] || cmd
    return self.send(cmd.to_sym) if ONE_SHOTS.include?(cmd) && tokens.length == 1
    return show_topic(cmd) if cmd =~ /^\d+$/
    # If we've gotten this far, we must have args. Let's handle 'em.
    arg = tokens.last
    return reply(arg)  if cmd == 'reply'
    return edit(arg)   if cmd == 'edit'
    return delete(arg) if cmd == 'delete'
    return mark_read(arg) if cmd == 'mark_read'
    Display.say 'Unrecognized command.  Type "help" for a list of available commands.'
  end

  def reset_display
    Display.say `tput reset`.chomp
  end

  def self.info
    topic_count          = Corpus.topics.size
    unread_topic_count   = Corpus.unread_topics.size
    message_count        = Corpus.size
    unread_message_count = Corpus.unread_messages.size
    author_count         = Corpus.all.map(&:author).uniq.size

    Display.flowerbox(
      "Iris #{Config::VERSION}",
      "#{topic_count} #{'topic'.pluralize(topic_count)}, #{unread_topic_count} unread.",
      "#{message_count} #{'message'.pluralize(message_count)}, #{unread_message_count} unread.",
      "#{author_count} #{'author'.pluralize(author_count)}.",
        box_thickness: 0)
  end

  def info
    Display.say
    Interface.info
    Display.say
  end

  def self.mark_all_read
    Corpus.mark_as_read(Corpus.unread_messages.map(&:hash))
  end

  def mark_all_read
    Display.say "Marking all messages as read..."
    Interface.mark_all_read
    Display.say "Done!"
  end

  def compose
    @mode = :composing
    @text_buffer = ''
    Display.say 'Writing a new topic.  Type a period on a line by itself to end message.'
  end

  def next
    Display.say

    if Corpus.unread_topics.size == 0
      Display.say "{gvi You're all caught up!  No new topics to read.}"
      return
    end

    message = Corpus.unread_topics.first
    @reply_topic = message.hash

    Display.say message.to_topic_display
    Display.say

    Corpus.mark_as_read([message.hash] + message.replies.map(&:hash))
  end

  def reply(topic_id = @reply_topic)
    unless topic_id
      Display.say "I can't reply to nothing! Include a topic ID or view a topic to reply to."
      return
    end

    if parent = (Corpus.find_topic_by_id(topic_id) || Corpus.find_topic_by_hash(topic_id))
      @reply_topic = parent.hash
    else
      Display.say "Could not reply; unable to find a topic with ID '#{topic_id}'"
      return
    end

    @mode = :replying
    @text_buffer = ''
    title = Corpus.find_topic_by_hash(parent.hash).truncated_message(Display::TITLE_WIDTH)
    Display.say
    Display.say "Writing a reply to topic '#{title}'"
    Display.say 'Type a period on a line by itself to end message.'
  end

  def edit(message_id = nil)
    unless message_id
      Display.say "I can't edit nothing! Include a message ID to edit."
      return
    end

    message =
      Corpus.find_message_by_hash(message_id) ||
      Corpus.find_message_by_id(message_id) ||
      Corpus.find_topic_by_id(message_id)

    unless message
      Display.say "Could not edit; unable to find a message with ID '#{message_id}'"
      return
    end

    unless Corpus.is_mine?(message)
      Display.say "Message with ID '#{message_id}' belongs to someone else."
      Display.say "You can only edit your own messages!"
      return
    end

    @mode = :editing
    @old_message = message
    @text_buffer = ''
    title = message.truncated_message(Display::TITLE_WIDTH)
    Display.say
    Display.say "Editing message '#{title}'"
    Display.say 'Type a period on a line by itself to end message.'
  end

  def mark_read(message_id = nil)
    unless message_id
      Display.say "I'm not a nihilist; I can't do something with nothing! Include a message ID to mark as read."
      return
    end

    message =
      Corpus.find_message_by_hash(message_id) ||
      Corpus.find_message_by_id(message_id) ||
      Corpus.find_topic_by_id(message_id)

    unless message
      Display.say "Could not mark as read; unable to find a message with ID '#{message_id}'"
      return
    end

    Corpus.mark_as_read([message.hash] + message.replies.map(&:hash))
  end

  def delete(message_id = nil)
    unless message_id
      Display.say "I'm not a nihilist; I can't do something with nothing! Include a message ID to delete or undelete."
      return
    end

    message =
      Corpus.find_message_by_hash(message_id) ||
      Corpus.find_message_by_id(message_id) ||
      Corpus.find_topic_by_id(message_id)

    unless message
      Display.say "Could not delete or undelete; unable to find a message with ID '#{message_id}'"
      return
    end

    unless Corpus.is_mine?(message)
      Display.say "Message with ID '#{message_id}' belongs to someone else."
      Display.say "You can only delete or undelete your own messages!"
      return
    end

    message.delete

    title = message.truncated_message(Display::TITLE_WIDTH)
    Display.say
    if message.is_deleted
      Display.say "{r Deleted message '#{title}' }"
    else
      Display.say "{y Undeleted message '#{title}' }"
    end
  end

  def replying_handler(line)
    line.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
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

  def editing_handler(line)
    if line !~ /^\.$/
      if @text_buffer.empty?
        @text_buffer = line
      else
        @text_buffer = [@text_buffer, line].join("\n")
      end
      return
    end

    if @text_buffer.length <= 1
      Display.say 'Empty message, not updating...'
    else
      Message.edit(@text_buffer, @old_message)
      Display.say 'Message edited!'
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
    return editing_handler(line)   if @mode == :editing
  end

  def show_topic(num)
    index = num.to_i - 1
    # TODO: Paginate here
    if index >= 0 && index < Corpus.topics.length
      msg = Corpus.topics[index]
      @reply_topic = msg.hash

      Display.say msg.to_topic_display
      Display.say

      Corpus.mark_as_read([msg.hash] + msg.replies.map(&:hash))
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
    return 'new~> '   if @mode == :composing
    return 'reply~> ' if @mode == :replying
    return 'edit~> '  if @mode == :editing
    "#{Config::AUTHOR}~> "
  end

  def initialize(args)
    @history_loaded = false
    @mode = :browsing

    Display.say "Welcome to Iris v#{Config::VERSION}.  Type 'help' for a list of commands; Ctrl-D or 'quit' to leave."
    unread

    while line = readline(prompt) do
      handle(line)
    end
  end

  def unread
    Display.say

    if Corpus.unread_topics.size == 0
      Display.say "{gvi You're all caught up!  No new topics to read.}"
      return
    end

    Display.say Display.topic_header
    # TODO: Paginate here
    Corpus.topics.each_with_index do |topic, index|
      if Corpus.unread_topics.include?(topic)
        Display.say topic.to_topic_line(index + 1)
      end
    end
    Display.say
  end

  def topics
    Display.say
    Display.say Display.topic_header
    # TODO: Paginate here
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
      'READING',
      'topics, t        - List all topics',
      'unread, u        - List all topics with unread messages',
      '# (topic id)     - Read specified topic',
      'next, n          - Read the next unread topic',
      'mark_read #, m # - Mark the associated topic as read',
      'mark_all_read    - Mark all messages as read',
      'help, h, ?       - Display this text',
      '',
      'WRITING',
      'compose, c       - Add a new topic',
      'reply #, r #     - Reply to a specific topic',
      'edit #, e #      - Edit a topic or message',
      'delete #, d #, undelete # - Delete {u or undelete} a topic or message',
      '',
      'SCREEN AND FILE UTILITIES',
      'freshen, f       - Reload to get any new messages',
      'reset, clear     - Fix screen in case of text corruption',
      'info, i          - Display Iris version and message stats',
      'quit, q          - Quit Iris',
      '',
      'Full documentation available here:',
      'https://github.com/Calamitous/iris/blob/master/README.md',
      box_character: '')
  end

  def freshen
    Corpus.load
    Display.say 'Reloaded!'
    unread
  end

  def readline(prompt)
    if !@history_loaded && File.exist?(Config::HISTORY_FILE)
      @history_loaded = true
      if File.readable?(Config::HISTORY_FILE)
        File.readlines(Config::HISTORY_FILE).each { |l| Readline::HISTORY.push(l.chomp) }
      end
    end

    if line = Readline.readline(prompt, true)
      if File.writable?(Config::HISTORY_FILE)
        File.open(Config::HISTORY_FILE) { |f| f.write(line+"\n") }
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
      "#{Config::IRIS_SCRIPT} [options]",
      '',
      'Options',
      '========',
      '--help, -h        - Display this text.',
      '--version, -v     - Display the current version of Iris.',
      '--stats, -s       - Display Iris version and message stats.',
      '--interactive, -i - Enter interactive mode (default)',
      '--mark-all-read   - Mark all messages as read.',
      '--dump, -d        - Dump entire message corpus out.',
      '--test-file <filename>, -f  <filename> - Use the specified test file for messages.',
      '--debug           - Print warnings and debug informtation during use.',
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
      Interface.info
      exit(0)
    end

    if (args & %w{-d --dump}).any?
      puts Corpus.to_json
      exit(0)
    end

    if (args & %w{--mark-all-read}).any?
      Interface.mark_all_read
      exit(0)
    end

    Display.say "Unrecognized option(s) #{args.join(', ')}"
    Display.say "Try -h for help"
    exit(1)
  end
end

class Startupper
  def initialize(args)
    perform_file_checks unless Config::NONFILE_OPTIONS.include?(args)

    load_corpus(args)

    is_interactive = (args & Config::NONINTERACTIVE_OPTIONS).none? || (args & Config::INTERACTIVE_OPTIONS).any?

    Config.enable_debug_mode if (args & %w{--debug}).any?

    if is_interactive
      Interface.start(args)
    else
      CLI.start(args)
    end
  end

  def perform_file_checks
    raise 'Should not try to perform file checks in test mode!' if $test_corpus_file
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

    IrisFile.create_read_file

    if File.stat(Config::MESSAGE_FILE).mode != 33188
      Display.permissions_error(Config::MESSAGE_FILE, 'message', '-rw-r--r--', '644', "Leaving your file with incorrect permissions could allow unauthorized edits!")
    end

    if File.stat(Config.readfile_filename).mode != 33188
      Display.permissions_error(Config.readfile_filename, 'read', '-rw-r--r--', '644')
    end

    if File.stat(Config::IRIS_SCRIPT).mode != 33261
      Display.permissions_error(Config::IRIS_SCRIPT, 'Iris', '-rwxr-xr-x', '755', 'If this file has the wrong permissions the program may be tampered with!')
    end
  end

  def load_corpus(args)
    $test_corpus_file = nil

    if (args & %w{-f --test-file}).any?
      filename_idx = (args.index('-f') || args.index('--test-file')) + 1
      filename = args[filename_idx]

      unless filename
        Display.say "Option `--test-file` (`-f`) expects a filename"
        exit(1)
      end

      unless File.exist?(filename)
        Display.say "Could not load test file: #{filename}"
        exit(1)
      end

      Display.say "Using Iris with test file: #{filename}"
      $test_corpus_file = filename
    end

    Corpus.load
  end
end

Startupper.new(ARGV) if __FILE__==$0

