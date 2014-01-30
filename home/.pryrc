#!/usr/env ruby

begin
  require 'pry-clipboard'
  # aliases
  Pry.config.commands.alias_command 'ch', 'copy-history'
  Pry.config.commands.alias_command 'cr', 'copy-result'
rescue LoadError => e
  warn "Can't load pry-clipboard. Is it installed for your current ruby?"
end

begin
  require 'pry-nav'
  # aliases
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
rescue LoadError => e
  warn "Can't load pry-nav. Is it installed for your current ruby?"
end

