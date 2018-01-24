#!/usr/bin/env ruby

#TODO: Validate author with file owner
#TODO: Create struct to firm up message payload

require 'time'
require 'base64'
require 'digest'
require 'socket'
require 'json'

class Config
  CONFIG_FILE  = "#{ENV['HOME']}/.iris.config.json"
  MESSAGE_FILE = "#{ENV['HOME']}/.iris.messages"

  USER         = ENV['USER'] || ENV['LOGNAME'] || ENV['USERNAME']
  HOSTNAME     = Socket.gethostname
  AUTHOR       = "#{USER}@#{HOSTNAME}"

  def self.get(filepath = CONFIG_FILE)
    return @loaded_config if @loaded_config
    if !File.exists?(filepath)
      File.write(filepath, '{}')
      return @loaded_config = {}
    end
    return @loaded_config = JSON.load(filepath)
  end
end

class Message
  TERMINATOR = "\n.\n"
  FIELD_SEPARATOR = '|'
  FILE_FORMAT = 'v1'

  attr_reader :timestamp, :hash, :edit_hash, :author, :parent, :message

  def initialize(message, author = Config::AUTHOR, parent = nil, timestamp = Time.now.utc.iso8601, edit_hash = nil)
    @parent    = parent
    @author    = author
    @timestamp = timestamp
    @message   = message
  end

  def self.load(payload)
    payload = payload.gsub(/#{TERMINATOR}$/, '')
    hash, edit_hash, timestamp, parent, author, *message = payload.split(FIELD_SEPARATOR)

    loaded_message = self.new(message.join(FIELD_SEPARATOR), author, parent, timestamp, edit_hash)
    raise 'Broken hash!' unless loaded_message.hash == hash
    loaded_message
  end

  def hash
    make_sha(unconfirmed_payload)
  end

  def to_payload
    [hash, @edit_hash, unconfirmed_payload].join(FIELD_SEPARATOR) + TERMINATOR
  end

  private

  def unconfirmed_payload
    [@timestamp, @parent, @author, @message].join(FIELD_SEPARATOR)
  end

  def make_sha(payload)
    Base64.encode64(Digest::SHA1.digest(payload))
  end
end

