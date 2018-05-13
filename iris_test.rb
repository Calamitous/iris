require 'minitest/autorun'
require 'mocha/mini_test'

# Setting this before loading the main code file so that the Config contants
# load correctly.  This will allows the test to pretend that user "jerryberry"
# is logged in.
ENV.stubs(:[]).returns('jerryberry')

require './iris.rb'

describe Config do
  it 'has the Iris semantic version number' do
    Config::VERSION.must_match /^\d\.\d\.\d$/
  end

  it 'has the message file location' do
    Config::MESSAGE_FILE.must_match /\/\.iris\.messages$/
  end

  it 'has the readline history file location' do
    Config::HISTORY_FILE.must_match /\/\.iris\.history$/
  end

  it 'has the username' do
    Config::USER.must_equal 'jerryberry'
  end

  it 'has a hostname' do
    Config::HOSTNAME.wont_be_nil
  end

  it 'has the author' do
    Config::AUTHOR.must_equal "#{Config::USER}@#{Config::HOSTNAME}"
  end

  describe '.find_files' do
    it 'looks up all the Iris message files on the system' do
      # I am so sorry
      Config.expects(:`).with('ls /home/**/.iris.messages').returns('')
      Config.find_files
    end

    it 'returns a list of Iris message files' do
      Config.stubs(:`).returns("foo\nbar\n")
      Config.find_files.must_equal ['foo', 'bar']
    end

    it 'returns an empty array if no Iris message files are found' do
      Config.stubs(:`).returns('')
      Config.find_files.must_equal []
    end
  end
end

describe Corpus do
  describe '.load' do
    it 'loads all the message files'
    it 'sets the corpus class variable'
    it 'sets the topics class variable'
    it 'creates a hash index'
    it 'creates parent-hash-to-child-indexes index'
  end

  describe '.all' do
    it 'returns the entire corpus of messages'
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
      Corpus.find_message_by_hash(nil).must_equal nil
    end

    it 'returns nil if the hash is not found in the corpus' do
      skip
      Corpus.find_message_by_hash('NoofMcGoof').must_equal nil
    end

    it 'returns the message associated with the hash if it is found'
  end

  describe '.find_all_by_parent_hash' do
    it 'returns an empty array if a nil is passed in' do
      Corpus.find_all_by_parent_hash(nil).must_equal []
    end

    it 'returns an empty array if the hash is not a parent of any other messages' do
      skip
      Corpus.find_all_by_parent_hash('GoofMcDoof').must_equal []
    end

    it 'returns an empty array if the hash is not found in the corpus'
    it 'returns the messages associated with the parent hash'
  end

  describe '.find_topic_by_id' do
    it 'returns nil if a nil is passed in' do
      Corpus.find_topic_by_id(nil).must_equal nil
    end

    describe 'when an index string is passed in' do
      it 'returns nil if the topic is not found'
      it 'returns the associated topic'
    end
  end

  describe '.find_topic_by_hash' do
    it 'returns nil if a nil is passed in' do
      Corpus.find_topic_by_hash(nil).must_equal nil
    end

    describe 'when a hash string is passed in' do
      it 'returns nil if the topic is not found'
      it 'returns the associated topic'
    end
  end
end

describe IrisFile do
  describe '.load_messages' do; end
  describe '.create_message_file' do; end
end

describe Message do
  it 'has a file version' do
    Message::FILE_FORMAT.must_match /v\d/
  end

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
    Display::MIN_WIDTH.must_equal 80
  end

  it 'has a setting for the calculated screen width'

  describe '#topic_index_width' do
    it 'returns the a minimun length of 2' do
      Corpus.stubs(:topics).returns(%w{a})
      Display.topic_index_width.must_equal 2
    end

    it 'returns the length in characters of the longest topic index' do
      Corpus.stubs(:topics).returns((0..1000).to_a)
      Display.topic_index_width.must_equal 4
    end

    it 'returns 2 if there are no topics' do
      Corpus.stubs(:topics).returns([])
      Display.topic_index_width.must_equal 2
    end
  end

  describe '#topic_author_width' do
    it 'returns the length in characters of the longest author\'s name'
    it 'returns 1 if there are no topics' do
      Corpus.stubs(:topics).returns([])
      Display.topic_author_width.must_equal 1
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
      Config.send(:remove_const, 'MESSAGE_FILE')
      Config.send(:remove_const, 'READ_FILE')
      Config.send(:remove_const, 'IRIS_SCRIPT')
      Config::MESSAGE_FILE = message_file_path
      Config::READ_FILE    = read_file_path
      Config::IRIS_SCRIPT  = 'doots'

      File.stubs(:exists?).returns(true)

      File.stubs(:stat).with(Config::IRIS_SCRIPT).returns(script_file_stat)
      File.stubs(:stat).with(message_file_path).returns(data_file_stat)
      File.stubs(:stat).with(read_file_path).returns(data_file_stat)

      Interface.stubs(:start)
      Display.stubs(:say)
    end

    it 'offers to create a message file if the user doesn\'t have one' do
      skip
      File.stubs(:exists?).with(message_file_path).returns(false)
      Readline.expects(:readline).with('Would you like me to create it for you? (y/n) ', true).returns('y')
      IrisFile.expects(:create_message_file)

      Startupper.new([])
    end

    it 'creates a read file if the user doesn\'t have one' do
      skip
      File.stubs(:exists?).with(read_file_path).returns(false)
      IrisFile.expects(:create_read_file)

      Startupper.new([])
    end

    it 'warns the user if the message file permissions are wrong' do
      File.stubs(:stat).with(message_file_path).returns(bad_file_stat)
      Display.expects(:say).with('Your message file has incorrect permissions!  Should be "-rw-r--r--".')

      Startupper.new([])
    end

    it 'warns the user if the read file permissions are wrong' do
      File.stubs(:stat).with(read_file_path).returns(bad_file_stat)
      Display.expects(:say).with('Your read file has incorrect permissions!  Should be "-rw-r--r--".')

      Startupper.new([])
    end

    it 'warns the user if the script file permissions are wrong' do
      File.expects(:stat).with(Config::IRIS_SCRIPT).returns(bad_file_stat)
      Display.expects(:say).with('The Iris file has incorrect permissions!  Should be "-rwxr-xr-x".')

      Startupper.new([])
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
  end
end

describe 'String#colorize' do
  let(:color_string) {
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
  "
  }

  it 'produces the expected output' do
    # color_string.split("\n")[1].colorize.must_equal "\n     RED     \e[31mnormal\e[0m\t\e[1;31mintense\e[0m\t\e[31;4munderline\e[0m\t\e[1;31;4mintense underline\e[0m\n             \e[31;7mreverse\e[0m\t\e[1;31;7mintense\e[0m\t\e[31;4;7munderline\e[0m\t\e[1;31;4;7mintense underline\e[0m\n     GREEN   \e[32mnormal\e[0m\t\e[1;32mintense\e[0m\t\e[32;4munderline\e[0m\t\e[1;32;4mintense underline\e[0m\n             \e[32;7mreverse\e[0m\t\e[1;32;7mintense\e[0m\t\e[32;4;7munderline\e[0m\t\e[1;32;4;7mintense underline\e[0m\n     YELLOW  \e[33mnormal\e[0m\t\e[1;33mintense\e[0m\t\e[33;4munderline\e[0m\t\e[1;33;4mintense underline\e[0m\n             \e[33;7mreverse\e[0m\t\e[1;33;7mintense\e[0m\t\e[33;4;7munderline\e[0m\t\e[1;33;4;7mintense underline\e[0m\n     BLUE    \e[34mnormal\e[0m\t\e[1;34mintense\e[0m\t\e[34;4munderline\e[0m\t\e[1;34;4mintense underline\e[0m\n             \e[34;7mreverse\e[0m\t\e[1;34;7mintense\e[0m\t\e[34;4;7munderline\e[0m\t\e[1;34;4;7mintense underline\e[0m\n     MAGENTA \e[35mnormal\e[0m\t\e[1;35mintense\e[0m\t\e[35;4munderline\e[0m\t\e[1;35;4mintense underline\e[0m\n             \e[35;7mreverse\e[0m\t\e[1;35;7mintense\e[0m\t\e[35;4;7munderline\e[0m\t\e[1;35;4;7mintense underline\e[0m\n     CYAN    \e[36mnormal\e[0m\t\e[1;36mintense\e[0m\t\e[36;4munderline\e[0m\t\e[1;36;4mintense underline\e[0m\n             \e[36;7mreverse\e[0m\t\e[1;36;7mintense\e[0m\t\e[36;4;7munderline\e[0m\t\e[1;36;4;7mintense underline\e[0m\n     WHITE   \e[37mnormal\e[0m\t\e[1;37mintense\e[0m\t\e[37;4munderline\e[0m\t\e[1;37;4mintense underline\e[0m\n             \e[37;7mreverse\e[0m\t\e[1;37;7mintense\e[0m\t\e[37;4;7munderline\e[0m\t\e[1;37;4;7mintense underline\e[0m\n  \e[0m"
    color_string.split("\n")[1].colorize.must_equal "    RED     \e[31mnormal\e[0m\t\e[1;31mintense\e[0m\t\e[31;4munderline\e[0m\t\e[1;31;4mintense underline\e[0m\e[0m"
  end

  it 'returns an empty string when provided an empty string' do
    ''.colorize.must_equal ''
  end

  it 'allows curly brackets to be escaped' do
    'I want \{no color\}'.colorize.must_equal "I want {no color}\e[0m"
  end
end

describe 'String#decolorize' do
  it 'returns the string with the coloring tags stripped'

  it 'allows curly brackets to be escaped' do
    'I want \{no color\}'.decolorize.must_equal "I want {no color}"
  end
end
