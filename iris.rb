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
  FILE_FORMAT = 'v2'

  attr_reader :timestamp, :hash, :edit_hash, :author, :parent, :message

  def initialize(message, author = Config::AUTHOR, parent = nil, timestamp = Time.now.utc.iso8601, edit_hash = nil)
    @parent    = parent
    @author    = author
    @timestamp = timestamp
    @message   = message
  end

  def self.load(payload)
    data = JSON.parse(payload)
    # hash, edit_hash, timestamp, parent, author, *message = payload.split(FIELD_SEPARATOR)

    loaded_message = self.new(data['data']['message'], data['data']['author'], data['data']['parent'], data['data']['timestamp'], data['edit_hash'])
    raise 'Broken hash!' unless loaded_message.hash == data['hash']
    loaded_message
  end

  def hash(payload = nil)
    payload ||= unconfirmed_payload.to_json
    Base64.encode64(Digest::SHA1.digest(payload))
  end

  def to_json
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

