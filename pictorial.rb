#!/usr/bin/env ruby
# encoding: UTF-8

#	pictorial.rb
#	Evadne Wu at Iridia Productions, 2010

require 'rubygems'
require 'optparse'
require 'pp'

require 'find'
require 'fileutils'
require 'pathname'

gem 'directory_watcher'
require 'directory_watcher'

gem 'ruby-growl'
require 'ruby-growl'

gem 'json'
require 'json'


PICTORIAL_PATH = Pathname.new(File.expand_path(File.dirname(__FILE__)))

load "#{PICTORIAL_PATH}/File+PictorialAdditions.rb"
load "#{PICTORIAL_PATH}/pictorial.core.rb"

Pictorial.initialize




