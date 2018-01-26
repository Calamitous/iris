#!/usr/bin/env ruby

#TODO: Validate author with file owner
#TODO: Create struct to firm up message payload
#TODO: Common message file location for the security-conscious?
#TODO: Check for proper file permissions on message file
#TODO: Use ENV for rows and cols of display?
#TODO: Add "read" list
#TODO: Fix hostname for domain name

require 'time'
require 'base64'
require 'digest'
require 'socket'
require 'json'
require 'etc'

class Config
  CONFIG_FILE  = "#{ENV['HOME']}/.iris.config.json"
  MESSAGE_FILE = "#{ENV['HOME']}/.iris.messages"

  USER         = ENV['USER'] || ENV['LOGNAME'] || ENV['USERNAME']
  HOSTNAME     = Socket.gethostname
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
    # TODO create file for current user
    return [] unless File.exists?(filepath)

    # TODO gracefully handle non-json files
    payload = JSON.parse(File.read(filepath))
    raise 'Invalid File!' unless payload.is_a?(Array)

    uid = File.stat(filepath).uid
    username = Etc.getpwuid(uid).name
    p username

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
    @@corpus = Config.find_files.map { |filepath| IrisFile.load_messages(filepath) }.flatten.sort_by(&:timestamp)
    @@topics = @@corpus.select{ |m| m.parent == nil }
    @@my_corpus = IrisFile.load_messages
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
    p new_corpus
    p new_corpus.to_json
    IrisFile.write_corpus(new_corpus.to_json)
    Corpus.load
  end

  def hash(payload = nil)
    payload ||= unconfirmed_payload.to_json
    Base64.encode64(Digest::SHA1.digest(payload))
  end

  def is_topic?
    parent.nil?
  end

  def to_json(*args)
    p args
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

Corpus.load
puts "#{Config::AUTHOR}>"

