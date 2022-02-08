# code from: https://github.com/myobie/sinatra-scope. Reason to persist "scope" method for Sinatra after gems upgrade

require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'
require 'sinatra/base'

module Sinatra
  module Scope

    [:get, :post, :patch, :put, :delete, :head, :options].each do |verb|
      define_method verb do |path = '', options = {}, &block|
        super(full_path(path), options, &block)
      end
    end

    [:before, :after].each do |action|
      define_method action do |path = '', options = {}, &block|
        super(full_path(path), options, &block)
      end
    end

    def scope(path, options = {}, &block)
      case path
      when Class
        path = path.name
        path = path.demodulize unless options[:full_classname]
        path = path.underscore.dasherize
        path = path.pluralize unless options[:singular]
      else
        path = path.to_s
      end

      (@scopes ||= []) << path
      block.call
      @scopes.pop
    end

    def scopes(*paths, &block)
      @scopes ||= []
      paths.each do |path|
        @scopes << path.to_s
      end
      block.call
      paths.each do |path|
        @scopes.pop
      end
    end

    protected
    def full_path(path)
      case path
      when String, Symbol
        ("/" + (@scopes || []).join("/") + path.to_s).squeeze("/")
      when Regexp
        Regexp.new(Regexp.escape("/" + (@scopes || []).join("/")) + path.source)
      else
        path
      end
    end

    def path_name(path)
      full_path(path).gsub(/^\//, '')
    end

  end

end