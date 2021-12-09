require 'minitest/autorun'
require 'mocha/minitest'

# This allows the test to pretend that user "jerryberry" is logged in.
ENV['USER'] = 'jerryberry'

ENV['EDITOR'] = 'foo/bar'

# Set this before loading the code so that the Config constants load correctly.
$test_corpus_file = "./tests/iris.messages.json"

require './iris.rb'

describe Config do
  it 'has the Iris semantic version number' do
    _(Config::VERSION).must_match /^\d\.\d\.\d+$/
  end

  it 'has the message file location' do
    _(Config::MESSAGE_FILE).must_match /\/\.iris\.messages$/
  end

  it 'has the readline history file location' do
    _(Config::HISTORY_FILE).must_match /\/\.iris\.history$/
  end

  it 'has the username' do
    _(Config::USER).must_equal 'jerryberry'
  end

  it 'has a hostname' do
    _(Config::HOSTNAME).wont_be_nil
  end

  it 'has the author' do
    _(Config::AUTHOR).must_equal "#{Config::USER}@#{Config::HOSTNAME}"
  end

  it 'has the $EDITOR environment variable' do
    _(Config::ENV_EDITOR).must_equal 'foo/bar'
  end

  describe '.find_files' do
    it 'looks up all the Iris message files on the system' do
      # I am so sorry about this `expects` clause
      Config.expects(:`).with('ls /home/**/.iris.messages').returns('')
      Config.find_files
    end

    it 'returns a list of Iris message files' do
      Config.stubs(:`).returns("foo\nbar\n")
      _(Config.find_files).must_equal ['foo', 'bar']
    end

    it 'returns an empty array if no Iris message files are found' do
      Config.stubs(:`).returns('')
      _(Config.find_files).must_equal []
    end
  end
end

describe Corpus do
  before do
    Corpus.load
  end

  describe '.load' do
    it 'loads all the message files'
    it 'sets the corpus class variable'
    it 'sets the topics class variable'
    it 'creates a hash index'
    it 'creates parent-hash-to-child-indexes index'
  end

  describe '.topics' do
    it 'returns all the messages which are topics'
    it 'does not return reply messages'
  end

  describe '.mine' do
    it 'returns all messages composed by the current user'
    it 'does not return any messages not composed by the current user'
  end

  describe '.find_message_by_hash' do
    it 'returns nil if a nil is passed in' do
      assert_nil Corpus.find_message_by_hash(nil)
    end

    it 'returns nil if the hash is not found in the corpus' do
      assert_nil Corpus.find_message_by_hash('NoofMcGoof')
    end

    it 'returns the message associated with the hash if it is found' do
      message = Corpus.find_message_by_hash("gpY2WW/jGcH+BODgySCwDANJlIM=\n")
      _(message.message).must_equal "Test"
    end
  end

  describe '.find_all_by_parent_hash' do
    it 'returns an empty array if a nil is passed in' do
      _(Corpus.find_all_by_parent_hash(nil)).must_equal []
    end

    it 'returns an empty array if the hash is not a parent of any other messages' do
      _(Corpus.find_all_by_parent_hash(nil)).must_equal []
    end

    it 'returns an empty array if the hash is not found in the corpus' do
      _(Corpus.find_all_by_parent_hash('GoofMcDoof')).must_equal []
    end

    it 'returns the messages associated with the parent hash'
  end

  describe '.find_topic_by_id' do
    it 'returns nil if a nil is passed in' do
      assert_nil Corpus.find_topic_by_id(nil)
    end

    describe 'when an index string is passed in' do
      it 'returns nil if the topic is not found' do
        assert_nil Corpus.find_topic_by_id('InvalidTopicId')
      end

      it 'returns the associated topic' do
        _(Corpus.find_topic_by_id(1).message).must_equal 'Test'
      end
    end
  end

  describe '.find_topic_by_hash' do
    it 'returns nil if a nil is passed in' do
      assert_nil Corpus.find_topic_by_hash(nil)
    end

    describe 'when a hash string is passed in' do
      it 'returns nil if the topic is not found' do
        assert_nil Corpus.find_topic_by_hash('BadHash')
      end

      it 'returns the associated topic' do
        _(Corpus.find_topic_by_hash("gpY2WW/jGcH+BODgySCwDANJlIM=\n").message).must_equal 'Test'
      end
    end
  end
end

describe IrisFile do
  describe '.load_messages' do; end
  describe '.create_message_file' do; end
end

describe Message do
  it 'exposes all its data attributes for reading'

  it 'is #valid? if it has no errors'
  it 'is #topic? if it has no parent'

  describe 'creation' do; end
  describe 'validation' do; end

  describe '#save!' do
    it 'adds itself to the user\'s corpus'
    it 'writes out the user\'s message file'
    it 'reloads all message files'
  end

  describe '#hash' do; end
  describe '#truncated_message' do; end
  describe '#to_topic_line' do; end
  describe '#to_display' do; end
  describe '#to_topic_display' do; end
  describe '#to_json' do; end
end

describe Display do
  it 'has a setting for a minimum width of 80' do
    _(Display::MIN_WIDTH).must_equal 80
  end

  it 'has a setting for a minimum height of 8' do
    _(Display::MIN_HEIGHT).must_equal 8
  end

  it 'has settings for the calculated screen geometry' do
    _(Display::WIDTH).wont_equal nil
    _(Display::HEIGHT).wont_equal nil
  end

  describe '#topic_index_width' do
    it 'returns the a minimun length of 2' do
      Corpus.stubs(:topics).returns(%w{a})
      _(Display.topic_index_width).must_equal 2
    end

    it 'returns the length in characters of the longest topic index' do
      Corpus.stubs(:topics).returns((0..1000).to_a)
      _(Display.topic_index_width).must_equal 4
    end

    it 'returns 2 if there are no topics' do
      Corpus.stubs(:topics).returns([])
      _(Display.topic_index_width).must_equal 2
    end
  end

  describe '#topic_author_width' do
    it 'returns the length in characters of the longest author\'s name' do
      Corpus.stubs(:authors).returns(['jerryberry@ctrl-c.club'])
      _(Display.topic_author_width).must_equal 22
    end

    it 'returns 1 if there are no topics' do
      Corpus.stubs(:authors).returns([])
      _(Display.topic_author_width).must_equal 1
    end
  end

  describe '.print_index' do; end
  describe '.print_author' do; end
end

describe Interface do
  it 'has a map of all single-word commands'
  it 'has a map of all shortcuts and commands'

  describe '#start' do; end
  describe 'creation' do; end

  describe '#reset_display' do; end
  describe '#reply' do; end
  describe '#show_topic' do; end
  describe '#quit' do; end
  describe '.start' do; end
  describe '#compose' do; end
  describe '#topics' do; end
  describe '#help' do; end
  describe '#freshen' do; end
  describe '#readline (maybe?)' do; end
end

describe CLI do
  describe '#start' do; end
  describe 'creation' do; end
  describe '--version or -v' do; end
  describe '--stats or -s' do; end
  describe '--help or -h' do; end
  describe 'junk parameters' do; end
end

describe Startupper do
  describe 'creation' do
    let(:message_file_path) { 'jerryberry/.iris.messages' }
    let(:read_file_path)    { 'jerryberry/.iris.read' }
    let(:data_file_stat)    { a = mock; a.stubs(:mode).returns(33188); a }
    let(:script_file_stat)  { a = mock; a.stubs(:mode).returns(33261); a }
    let(:bad_file_stat)     { a = mock; a.stubs(:mode).returns(2); a }

    before do
      Config.stubs(:find_files).returns([])
      IrisFile.stubs(:load_messages).returns([])
      IrisFile.stubs(:load_reads).returns([])

      Config.send(:remove_const, 'MESSAGE_FILE') if Config.const_defined? 'MESSAGE_FILE'
      Config.send(:remove_const, 'READ_FILE') if Config.const_defined? 'READ_FILE'
      Config.send(:remove_const, 'IRIS_SCRIPT') if Config.const_defined? 'IRIS_SCRIPT'
      Config::MESSAGE_FILE         = message_file_path
      Config::READ_FILE            = read_file_path
      Config.stubs(:messagefile_filename).returns(message_file_path)
      Config.stubs(:readfile_filename).returns(read_file_path)
      Config::IRIS_SCRIPT  = 'doots'

      File.stubs(:exists?).returns(true)

      File.stubs(:stat).with(Config::IRIS_SCRIPT).returns(script_file_stat)
      File.stubs(:stat).with(message_file_path).returns(data_file_stat)
      File.stubs(:stat).with(read_file_path).returns(data_file_stat)

      Interface.stubs(:start)
    end

    it 'starts the Interface if no command-line arguments are provided' do
      Interface.expects(:start).with([])
      Startupper.new([])
    end

    it 'starts the Interface if "-i" is provided at the command-line' do
      Interface.expects(:start).with(['-i'])
      Startupper.new(['-i'])
    end

    it 'starts the Interface if "--interactive" is provided at the command-line' do
      Interface.expects(:start).with(['--interactive'])
      Startupper.new(['--interactive'])
    end

    it 'starts the CLI if any non-interactive parameters are provided at the command-line' do
      CLI.expects(:start).with(['-h'])
      Startupper.new(['-h'])
    end

    it 'offers to create a message file if the user doesn\'t have one' do
      File.stubs(:exists?).with(message_file_path).returns(false)
      Display.stubs(:say)
      Readline.expects(:readline).with('Would you like me to create it for you? (y/n) ', true).returns('y')
      IrisFile.expects(:create_message_file)

      Startupper.new([])
    end

    it 'creates a read file if the user doesn\'t have one' do
      File.stubs(:exists?).with(read_file_path).returns(false)
      IrisFile.expects(:create_read_file)

      Startupper.new([])
    end

    it 'warns the user if the message file permissions are wrong' do
      File.expects(:stat).with(message_file_path).returns(bad_file_stat)
      Display.stubs(:say)
      message_lines = [
        "Your message file has incorrect permissions!  Should be \"-rw-r--r--\".",
        "You can change this from the command line with:",
        "  chmod 644 jerryberry/.iris.messages",
        "Leaving your file with incorrect permissions could allow unauthorized edits!"
      ]
      Display.expects(:say).with(message_lines)

      Startupper.new([])
    end

    it 'warns the user if the read file permissions are wrong' do
      File.stubs(:stat).with(read_file_path).returns(bad_file_stat)
      Display.stubs(:say)
      message_lines = [
        "Your read file has incorrect permissions!  Should be \"-rw-r--r--\".",
        "You can change this from the command line with:",
        "  chmod 644 jerryberry/.iris.read"
      ]
      Display.expects(:say).with(message_lines)

      Startupper.new([])
    end

    it 'warns the user if the script file permissions are wrong' do
      File.expects(:stat).with(Config::IRIS_SCRIPT).returns(bad_file_stat)
      Display.stubs(:say)
      message_lines = [
        "Your Iris file has incorrect permissions!  Should be \"-rwxr-xr-x\".",
        "You can change this from the command line with:",
        "  chmod 755 doots", "If this file has the wrong permissions the program may be tampered with!"
      ]
      Display.expects(:say).with(message_lines)

      Startupper.new([])
    end
  end
end

describe 'String#colorize' do
  let(:color_strings) {
    "
    RED     {r normal}\t{ri intense}\t{ru underline}\t{riu intense underline}
            {rv reverse}\t{riv intense}\t{ruv underline}\t{riuv intense underline}
    GREEN   {g normal}\t{gi intense}\t{ug underline}\t{uig intense underline}
            {gv reverse}\t{giv intense}\t{ugv underline}\t{uigv intense underline}
    YELLOW  {y normal}\t{yi intense}\t{yu underline}\t{yiu intense underline}
            {yv reverse}\t{yiv intense}\t{yuv underline}\t{yiuv intense underline}
    BLUE    {b normal}\t{bi intense}\t{bu underline}\t{biu intense underline}
            {bv reverse}\t{biv intense}\t{buv underline}\t{biuv intense underline}
    MAGENTA {m normal}\t{mi intense}\t{mu underline}\t{miu intense underline}
            {mv reverse}\t{miv intense}\t{muv underline}\t{miuv intense underline}
    CYAN    {c normal}\t{ci intense}\t{cu underline}\t{ciu intense underline}
            {cv reverse}\t{civ intense}\t{cuv underline}\t{ciuv intense underline}
    WHITE   {w normal}\t{wi intense}\t{wu underline}\t{wiu intense underline}
            {wv reverse}\t{wiv intense}\t{wuv underline}\t{wiuv intense underline}
    ".split("\n")[1..-2]
  }

  it 'produces the expected output' do
    lead = "\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m    "
    lines = [
      "RED     \e[31mnormal\e[0m\t\e[1;31mintense\e[0m\t\e[31;4munderline\e[0m\t\e[1;31;4mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "        \e[31;7mreverse\e[0m\t\e[1;31;7mintense\e[0m\t\e[31;4;7munderline\e[0m\t\e[1;31;4;7mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "GREEN   \e[32mnormal\e[0m\t\e[1;32mintense\e[0m\t\e[32;4munderline\e[0m\t\e[1;32;4mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "        \e[32;7mreverse\e[0m\t\e[1;32;7mintense\e[0m\t\e[32;4;7munderline\e[0m\t\e[1;32;4;7mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "YELLOW  \e[33mnormal\e[0m\t\e[1;33mintense\e[0m\t\e[33;4munderline\e[0m\t\e[1;33;4mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "        \e[33;7mreverse\e[0m\t\e[1;33;7mintense\e[0m\t\e[33;4;7munderline\e[0m\t\e[1;33;4;7mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "BLUE    \e[34mnormal\e[0m\t\e[1;34mintense\e[0m\t\e[34;4munderline\e[0m\t\e[1;34;4mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "        \e[34;7mreverse\e[0m\t\e[1;34;7mintense\e[0m\t\e[34;4;7munderline\e[0m\t\e[1;34;4;7mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "MAGENTA \e[35mnormal\e[0m\t\e[1;35mintense\e[0m\t\e[35;4munderline\e[0m\t\e[1;35;4mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "        \e[35;7mreverse\e[0m\t\e[1;35;7mintense\e[0m\t\e[35;4;7munderline\e[0m\t\e[1;35;4;7mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "CYAN    \e[36mnormal\e[0m\t\e[1;36mintense\e[0m\t\e[36;4munderline\e[0m\t\e[1;36;4mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "        \e[36;7mreverse\e[0m\t\e[1;36;7mintense\e[0m\t\e[36;4;7munderline\e[0m\t\e[1;36;4;7mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "WHITE   \e[37mnormal\e[0m\t\e[1;37mintense\e[0m\t\e[37;4munderline\e[0m\t\e[1;37;4mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
      "        \e[37;7mreverse\e[0m\t\e[1;37;7mintense\e[0m\t\e[37;4;7munderline\e[0m\t\e[1;37;4;7mintense underline\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m\e[0m",
    ]

    _(color_strings[0].colorize).must_equal lead + lines[0]
    _(color_strings[1].colorize).must_equal lead + lines[1]
    _(color_strings[2].colorize).must_equal lead + lines[2]
    _(color_strings[3].colorize).must_equal lead + lines[3]
    _(color_strings[4].colorize).must_equal lead + lines[4]
    _(color_strings[5].colorize).must_equal lead + lines[5]
    _(color_strings[6].colorize).must_equal lead + lines[6]
    _(color_strings[7].colorize).must_equal lead + lines[7]
    _(color_strings[8].colorize).must_equal lead + lines[8]
    _(color_strings[9].colorize).must_equal lead + lines[9]
    _(color_strings[10].colorize).must_equal lead + lines[10]
    _(color_strings[11].colorize).must_equal lead + lines[11]
    _(color_strings[12].colorize).must_equal lead + lines[12]
    _(color_strings[13].colorize).must_equal lead + lines[13]
  end

  it 'returns an empty string wrapped with resets when provided an empty string' do
    _(''.colorize).must_equal "\e[0m\e[0m"
  end

  it 'allows curly brackets to be escaped' do
    _('I want \{no color\}'.colorize).must_equal "\e[0m\e[0mI want {no color}\e[0m\e[0m\e[0m"
  end
end

describe 'String#decolorize' do
  it 'returns the string with the coloring tags stripped' do
    _("{b colorful}".decolorize).must_equal "colorful"
  end

  it 'allows curly brackets to be escaped' do
    _('I want \{no color\}'.decolorize).must_equal "I want {no color}"
  end
end
