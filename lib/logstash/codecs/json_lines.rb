# encoding: utf-8
require "logstash/codecs/base"
require "logstash/util/charset"
require "logstash/util/buftok"
require "logstash/json"

# This codec will decode streamed JSON that is newline delimited.
# Encoding will emit a single JSON string ending in a `@delimiter`
# NOTE: Do not use this codec if your source input is line-oriented JSON, for
# example, redis or file inputs. Rather, use the json codec.
# More info: This codec is expecting to receive a stream (string) of newline
# terminated lines. The file input will produce a line string without a newline.
# Therefore this codec cannot work with line oriented inputs.
class LogStash::Codecs::JSONLines < LogStash::Codecs::Base
  config_name "json_lines"

  # The character encoding used in this codec. Examples include `UTF-8` and
  # `CP1252`
  #
  # JSON requires valid `UTF-8` strings, but in some cases, software that
  # emits JSON does so in another encoding (nxlog, for example). In
  # weird cases like this, you can set the charset setting to the
  # actual encoding of the text and logstash will convert it for you.
  #
  # For nxlog users, you'll want to set this to `CP1252`
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  # Change the delimiter that separates lines
  config :delimiter, :validate => :string, :default => "\n"

  # If true, the event's metadata (the `@metadata` field) will be
  # included when used as an output codec.
  config :metadata, :validate => :boolean, :default => false

  public

  def register
    @buffer = FileWatch::BufferedTokenizer.new(@delimiter)
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
    if @metadata
      @encoder = method(:encode_with_metadata)
    else
      @encoder = method(:encode_default)
    end
  end

  def decode(data, &block)
    @buffer.extract(data).each do |line|
      parse(@converter.convert(line), &block)
    end
  end

  def encode(event)
    @encoder.call(event)
  end

  private

  def encode_default(event)
    # Tack on a @delimiter for now because previously most of logstash's JSON
    # outputs emitted one per line, and whitespace is OK in json.
    @on_event.call(event, "#{event.to_json}#{@delimiter}")
  end

  def encode_with_metadata(event)
    # Tack on a @delimiter for now because previously most of logstash's JSON
    # outputs emitted one per line, and whitespace is OK in json.
    @on_event.call(event, "#{event.to_json_with_metadata}#{@delimiter}")
  end

  # from_json_parse uses the Event#from_json method to deserialize and directly produce events
  def from_json_parse(json, &block)
    LogStash::Event.from_json(json).each { |event| yield event }
  rescue LogStash::Json::ParserError
    yield LogStash::Event.new("message" => json, "tags" => ["_jsonparsefailure"])
  end

  # legacy_parse uses the LogStash::Json class to deserialize json
  def legacy_parse(json, &block)
    # ignore empty/blank lines which LogStash::Json#load returns as nil
    o = LogStash::Json.load(json)
    yield(LogStash::Event.new(o)) if o
  rescue LogStash::Json::ParserError
    yield LogStash::Event.new("message" => json, "tags" => ["_jsonparsefailure"])
  end

  # keep compatibility with all v2.x distributions. only in 2.3 will the Event#from_json method be introduced
  # and we need to keep compatibility for all v2 releases.
  alias_method :parse, LogStash::Event.respond_to?(:from_json) ? :from_json_parse : :legacy_parse
end
