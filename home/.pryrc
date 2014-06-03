# === EDITOR ===
Pry.config.editor = 'vim'
Pry.config.color = true
Pry.config.history.should_save = true
Pry.config.should_load_local_rc = Dir.pwd != Dir.home

def pbcopy(data)
  IO.popen 'pbcopy', 'w' do |io|
    io << data
  end
  nil
end

def pbpaste
  `pbpaste`
end

# wrap ANSI codes so Readline knows where the prompt ends
def color(name, text)
  if Pry.color
    "\001#{Pry::Helpers::Text.send name, '{text}'}\002".sub '{text}', "\002#{text}\001"
  else
    text
  end
end

# === CUSTOM PROMPT ===
Pry.prompt = [
  proc { |obj, nest_level, _|
    "(#{obj}):#{nest_level} > "
  }, proc { |obj, nest_level, _|
    "(#{obj}):#{nest_level} * "
  }
]
Pry.config.prompt = Pry::NAV_PROMPT

# pretty prompt
# Pry.config.prompt = [
#   proc do |object, nest_level, pry|
#     prompt  = colour :bright_red, Pry.view_clip(object)
#     prompt += ":#{nest_level}" if nest_level > 0
#     prompt += colour :cyan, ' » '
#   end, proc { |object, nest_level, pry| colour :cyan, '» ' }
# ]

# === Pry Debugger ===
begin
  gem "pry-debugger"
rescue LoadError => e
else
  #Pry.config.commands.import default_command_set
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end

# === Listing config ===
# Better colors - by default the headings for methods are too
# similar to method name colors leading to a "soup"
# These colors are optimized for use with Solarized scheme
# for your terminal
Pry.config.ls.separator = "\n" # new lines between methods
Pry.config.ls.heading_color = :magenta
Pry.config.ls.public_method_color = :green
Pry.config.ls.protected_method_color = :yellow
Pry.config.ls.private_method_color = :bright_black

# == PLUGINS ===
# awesome_print gem: great syntax colorized printing
# look at ~/.aprc for more settings for awesome_print
begin
  require 'awesome_print'
  ## The following line enables awesome_print for all pry output,
  ## and it also enables paging
  Pry.config.print = proc {|output, value| Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output)}

  # If you want awesome_print without automatic pagination, use the line below
  # Pry.config.print = proc { |output, value| output.puts value.ai }
rescue LoadError => err
  puts "gem install awesome_print  # <-- highly recommended"
end

begin
  require 'hirb'
rescue LoadError => err
  puts "gem install hirb # <-- highly recommended"
end

# https://github.com/pry/pry/wiki/faq#wiki-hirb
if defined? Hirb
  # Slightly dirty hack to fully support in-session Hirb.disable/enable toggling
  Hirb::View.instance_eval do
    def enable_output_method
      @output_method = true
      @old_print = Pry.config.print
      Pry.config.print = proc do |output, value|
        Hirb::View.view_or_page_output(value) || @old_print.call(output, value)
      end
    end

    def disable_output_method
      Pry.config.print = @old_print
      @output_method = nil
    end
  end

  Hirb.enable
end

# === CUSTOM COMMANDS ===
# from: https://gist.github.com/1297510
Pry::CommandSet.new do
  command "copy", "Copy argument to the clip-board" do |str|
     IO.popen('pbcopy', 'w') { |f| f << str.to_s }
  end
  command "clear" do
    system 'clear'
    if ENV['RAILS_ENV']
      output.puts "Rails Environment: " + ENV['RAILS_ENV']
    end
  end
  command "sql", "Send sql over AR." do |query|
    if ENV['RAILS_ENV'] || defined?(Rails)
      pp ActiveRecord::Base.connection.select_all(query)
    else
      pp "No rails env defined"
    end
  end
  command "caller_method" do |depth|
    depth = depth.to_i || 1
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ caller(depth+1).first
      file   = Regexp.last_match[1]
      line   = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      output.puts [file, line, method]
    end
  end
end


# === CONVENIENCE METHODS ===
# Stolen from https://gist.github.com/807492
# Use Array.toy or Hash.toy to get an array or hash to play with
class Array
  def self.toy(n=10, &block)
    block_given? ? Array.new(n,&block) : Array.new(n) {|i| i+1}
  end
end

class Hash
  def self.toy(n=10)
    Hash[Array.toy(n).zip(Array.toy(n){|c| (96+(c+1)).chr})]
  end
end

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

#Reformat Exception
Pry.config.exception_handler = proc do |output, exception, _|
  output.puts "\e[31m#{exception.class}: #{exception.message}"
  output.puts "from #{exception.backtrace.first}\e[0m"
end

# === COLOR CUSTOMIZATION ===
Pry.config.theme = "solarized"

railsrc_path = File.expand_path("~/.railsrc")
if ( ENV['RAILS_ENV'] || defined? Rails ) && File.exist?( railsrc_path )
  begin
    load railsrc_path
  rescue Exception
    warn "Could not load: #{ railsrc_path } because of #{$!.message}" # because of $!.message
  end
end
