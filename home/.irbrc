# ruby 1.8.7 compatible
require 'rubygems'
require 'irb/completion'

# configure irb
IRB.conf[:PROMPT_MODE] = :SIMPLE

# where history is saved
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"

# irb history
IRB.conf[:SAVE_HISTORY] = 1000
# IRB.conf[:EVAL_HISTORY] = 1000

# IRB.conf[:AUTO_INDENT]=true
IRB.conf[:USE_READLINE] = true


ANSI = {}
ANSI[:RESET]     = "\e[0m"
ANSI[:BOLD]      = "\e[1m"
ANSI[:UNDERLINE] = "\e[4m"
ANSI[:LGRAY]     = "\e[0;37m"
ANSI[:GRAY]      = "\e[0;90m"
ANSI[:RED]       = "\e[31m"
ANSI[:GREEN]     = "\e[32m"
ANSI[:YELLOW]    = "\e[33m"
ANSI[:BLUE]      = "\e[34m"
ANSI[:MAGENTA]   = "\e[35m"
ANSI[:CYAN]      = "\e[36m"
ANSI[:WHITE]     = "\e[37m"


# Loading extensions of the console. This is wrapped
# because some might not be included in your Gemfile
# and errors will be raised
def extend_console(name, care = true, required = true)
  if care
    require name if required
    yield if block_given?
    $console_extensions << "#{ANSI[:GREEN]}#{name}#{ANSI[:RESET]}"
  else
    $console_extensions << "#{ANSI[:GRAY]}#{name}#{ANSI[:RESET]}"
  end
rescue LoadError
  $console_extensions << "#{ANSI[:RED]}#{name}#{ANSI[:RESET]}"
end
$console_extensions = []

# interactive editor: use vim from within irb
extend_console 'interactive_editor'

# awesome print
extend_console 'awesome_print' do
  alias pp ap
  AwesomePrint.irb!
end

extend_console 'irbtools' do
  FancyIrb.options[:colorize][:rocket_prompt] = :yellow
  FancyIrb.options[:colorize][:stdout] = :white
end

extend_console 'irbtools/more'

extend_console 'wirb' do
  Wirb.start

  Wirb.schema = {
    # object
    :open_object=>[:green],
    :object_class=>[:green, :bright],
    :object_address=>[:yellow, :underline],
    :object_description_prefix=>[:green],
    :object_description=>[:white], # this is the main color
    :object_variable_prefix=>[:magenta, :bright],
    :object_line_prefix=>[:yellow, :underline],
    :object_line=>[:yellow, :underline],
    :object_address_prefix=>[:yellow, :underline],
    :object_line_number=>[:brown, :underline],
    :object_variable=>[:magenta, :bright],
    :close_object=>[:green],

    # class
    :class_separator=>[:green],
    :class=>[:green, :bright],

    # container
    :open_array=>[:green, :bright],
    :close_array=>[:green, :bright],
    :open_hash=>[:green, :bright],
    :close_hash=>[:green, :bright],
    :open_set=>[:green],
    :close_set=>[:green],

    # string
    # :string=>[:black, :bright],
    :string=>[:green],
    :open_string=>[:white],
    :close_string=>[:white],

    # symbol
    :symbol_prefix=>[:yellow, :bright],
    :symbol=>[:yellow, :bright],
    :symbol_string=>[:yellow, :bright],
    :open_symbol_string=>[:yellow],
    :close_symbol_string=>[:yellow],

    # gem
    :gem_requirement_version=>[:cyan, :bright],
    :gem_requirement_condition=>[:cyan],

    # delimiter colors
    :comma=>[:green],
    :refers=>[:green],

    # regex
    :open_regexp=>[:blue, :bright],
    :regexp=>[:white],
    :regexp_flags=>[:red, :bright],
    :close_regexp=>[:blue, :bright],

    # number
    :range=>[:red],
    :number=>[:cyan, :bright],
    :open_rational=>[:cyan, :bright],
    :close_rational=>[:cyan, :bright],
    :rational_separator=>[:cyan, :bright],

    # misc
    :nil=>[:red, :bright],
    :true=>[:green],
    :false=>[:red],
    :time=>[:magenta],

    :colorizer=>[:Paint, :Wirb0_Paint],
    :name=>:custom
  }
end


# Show results of all extension-loading
puts "#{ANSI[:GRAY]}~> Console extensions:#{ANSI[:RESET]} #{$console_extensions.join(' ')}#{ANSI[:RESET]}"


class Object
  def local_methods
    case self.class
    when Class
      self.public_methods.sort - Object.public_methods
    when Module
      self.public_methods.sort - Module.public_methods
    else
      self.public_methods.sort - Object.new.public_methods
    end
  end
end

# Simple regular expression helper
# show_regexp - stolen from the pickaxe
def show_regexp(a, re)
   if a =~ re
      "#{$`}<<#{$&}>>#{$'}"
   else
      "no match"
   end
end

# Convenience method on Regexp so you can do
# /an/.show_match("banana")
class Regexp
  def show_match(a)
    show_regexp(a, self)
  end
end

# toys methods to play with.
# Stealed from https://gist.github.com/807492
class Array
  def self.toy(n=10,&block)
    block_given? ? Array.new(n,&block) : Array.new(n) {|i| i+1}
  end
end

class Hash
  def self.toy(n=10)
    Hash[Array.toy(n){|c| (96+(c+1)).chr.to_sym}.zip(Array.toy(n))]
  end
end

# pm - Print methods of objects in irb/console sessions.
def pm(obj, *options) # Print methods
  methods = obj.methods
  methods -= Object.methods unless options.include? :more
  filter = options.select {|opt| opt.kind_of? Regexp}.first
  methods = methods.select {|name| name =~ filter} if filter

  data = methods.sort.collect do |name|
    method = obj.method(name)
    if method.arity == 0
      args = "()"
    elsif method.arity > 0
      n = method.arity
      args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")})"
    elsif method.arity < 0
      n = -method.arity
      args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")}, ...)"
    end
    klass = $1 if method.inspect =~ /Method: (.*?)#/
    [name, args, klass]
  end
  max_name = data.collect {|item| item[0].size}.max
  max_args = data.collect {|item| item[1].size}.max
  data.each do |item|
    print "#{item[0].rjust(max_name)}"
    print "#{item[1].ljust(max_args)}"
    print "#{item[2]}\n"
  end
  data.size
end


railsrc_path = File.expand_path("~/.railsrc")
if ( ENV['RAILS_ENV'] || defined? Rails ) && File.exist?( railsrc_path )

  # set a nice prompt
  rails_root = File.basename(Dir.pwd)
  IRB.conf[:PROMPT] ||= {}
  IRB.conf[:PROMPT][:RAILS] = {
    :PROMPT_I => "#{rails_root}> ", # normal prompt
    :PROMPT_S => "#{rails_root}* ", # prompt when continuing a string
    :PROMPT_C => "#{rails_root}? ", # prompt when continuing a statement
    :RETURN   => "=> %s\n"          # prefixes output
  }
  IRB.conf[:PROMPT_MODE] = :RAILS

  # turn on the loud logging by default
  IRB.conf[:IRB_RC] = Proc.new { loud_logger }

  begin
    load railsrc_path
  rescue Exception
    warn "Could not load: #{ railsrc_path } because of #{$!.message}" # because of $!.message
  end
end
