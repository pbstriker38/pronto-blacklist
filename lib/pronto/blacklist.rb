require 'pronto/blacklist/version'
require 'pronto'
require 'pathspec'

module Pronto
  class Blacklist < Runner
    def run
      return [] unless @patches

      @patches.select { |patch| patch.additions > 0 }
        .map { |patch| inspect(patch) }
        .flatten
        .compact
    end

    private

    def inspect(patch)
      return if patch.delta.new_file[:path] == '.pronto-blacklist.yml'

      patch.added_lines.map do |line|
        blacklist_strings.map do |blacklist_string|
          new_message(line, blacklist_string) if match?(line, blacklist_string)
        end
      end
    end

    def match?(line, blacklist_string)
      options = options_for(blacklist_string)

      if options['exclude'] && options['exclude'].any?
        return false if PathSpec.new(options['exclude']).match(line.patch.new_file_full_path)
      end

      # if we should check comments for occurance of blacklisted string
      if !evaluate_comments?(options)
        return false if line.strip.start_with?("#")
      end

      if options['case_sensitive'] == false
        return line.content.downcase.include?(blacklist_string.downcase)
      end

      line.content.include?(blacklist_string)
    end

    # should we check comments for occurances of blacklisted string?
    def evaluate_comments?(options)
      return false if options['ignore_comments'] == false
      # default to true if the option isn't set
      true
    end

    def new_message(line, word)
      path = line.patch.delta.new_file[:path]

      Message.new(path, line, :error, "Do not use #{word}", nil, self.class)
    end

    def blacklist_strings
      @blacklist_strings ||= config_hash['blacklist'] || []
    end

    def options_for(blacklist_string)
      config_hash['options'][blacklist_string] || {}
    end

    def config_hash
      @config_hash ||= begin
        config_path = File.expand_path(File.join('./', '.pronto-blacklist.yml'))
        if File.exist?(config_path)
          YAML.load_file(config_path)
        else
          {}
        end
      end
    end
  end
end
