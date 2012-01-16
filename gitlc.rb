#!/usr/bin/env ruby




module GitLineCount
  class Reducer
    def initialize(commits, author_aliases = nil)
      @commits = commits
      @author_aliases = author_aliases || {}
    end

    def by_commit
      @commits
    end

    def by_date
      dates = {}
      @commits.each do |commit, values|
        #next unless values && values[:author]
        date = values[:date]
        dates[date] ||= {:net => 0, :adds=>0, :deletes=>0}
        dates[date][:net] += values[:adds] - values[:deletes]
        dates[date][:adds] += values[:adds]
        dates[date][:deletes] += values[:deletes]
      end
      dates.sort { |a, b| b[1][:date] <=> a[1][:date] }
    end

    def by_month
      dates = {}
      @commits.each do |commit, values|
        date = values[:date][0..6]
        dates[date] ||= {:net => 0, :adds=>0, :deletes=>0}
        dates[date][:net] += values[:adds] - values[:deletes]
        dates[date][:adds] += values[:adds]
        dates[date][:deletes] += values[:deletes]
      end
      dates.sort { |a, b| b[1][:date] <=> a[1][:date] }
    end

    def by_person
      people = {}
      @commits.each do |commit, values|
        next unless values && values[:author]
        authors = values[:author].split(/\+|\.and\./)
        authors.each do |author|
          author = canonical_name(author)
          people[author] ||= {:net => 0, :adds=>0, :deletes=>0}
          people[author][:net] += values[:adds] - values[:deletes]
          people[author][:adds] += values[:adds]
          people[author][:deletes] += values[:deletes]
        end
      end
      people.sort { |a, b| b[1][:net] <=> a[1][:net] }
    end

    private

    def canonical_name(name)
      @author_aliases[name] || name
    end
  end


  class Extractor

    def initialize(options, &add_commit_fn)
      @options = options
      @add_commit_fn = add_commit_fn
    end

    def extract!
      log = extract_log
      parse_commits(log)
    end

    private

    def extract_log
      restrictions = ''
      restrictions << "-#{@options[:count]} " if @options[:count] > 0
      restrictions << "--since #{@options[:since]} " if @options[:since]
      restrictions << "--author=#{@options[:author]} " if @options[:author]
      `cd #{@options[:repository]} && git log #{restrictions} --stat --date=short`.split("\n")
    end

    def parse_commits(log)
      adds, deletes, author, commit, date = 0, 0, nil, nil, nil
      log.each do |line|
        if line =~ /^commit ([0-9a-f]+)/
          @add_commit_fn.call(commit, deletes, adds, author, date) if commit
          adds, deletes, author, commit, date = 0, 0, nil, $1, nil
        elsif line =~ /Date:\s+(.*)/
          date = $1
        elsif line =~ /Author: .*<(pair\+)?(.*)@.*>/ # don't care about domain (now)
          author = $2
        elsif line =~ /\d+ files changed, (\d+) insertions\(\+\), (\d+) deletions\(\-\)/
          adds = $1
          deletes = $2
        end
      end
      @add_commit_fn.call(commit, deletes, adds, author, date) if commit
    end

  end
end








# begin script
require 'optparse'
options = {}
options_parser = OptionParser.new do |opts|

  opts.banner = "Usage: gitlc.rb [options] -r <dir>"

  ## Define the options, and what they do
  options[:repository] = '.'
  opts.on('-r', '--repo DIRECTORY', 'Count files in this repository directory') do |r|
    options[:repository] = r
  end

  options[:author_aliases] = {}
  opts.on('-A', '--aliases file.yml', 'YAML file with aliases for authors') do |f|
    require 'yaml'
    YAML::load(File.open(f)).each do |name, aliases|
      aliases.each { |a| options[:author_aliases][a] = name }
    end
  end

  options[:count] = 0
  opts.on('-c', '--count c', 'Number of versions to investigate') do |c|
    options[:count] = c.to_i
  end

  options[:since] = nil
  opts.on('-s', '--since c', 'Show commits more recent than a specific date') do |d|
    options[:since] = d
  end

  options[:author] = nil
  opts.on('-a', '--author a', 'Show commits by given author') do |a|
    options[:author] = a
  end

  options[:people] = false
  opts.on('-p', '--people', 'Show commit data by person') do
    options[:people] = true
  end

  options[:date] = false
  opts.on('-d', '--date', 'Show commit data by date') do
    options[:date] = true
  end

  options[:month] = false
  opts.on('-m', '--month', 'Show commit data by month') do
    options[:month] = true
  end

  options[:log] = false
  opts.on('-l', '--log', 'Show commit data') do
    options[:log] = true
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end
options_parser.parse!


@commits = Hash.new
collector = lambda do |commit, deletes, adds, author, date|
  @commits[commit] = {:deletes=>deletes.to_i, :adds=>adds.to_i, :author=>author, :date=>date}
end

GitLineCount::Extractor.new(options, &collector).extract!

r = GitLineCount::Reducer.new(@commits, options[:author_aliases])

# output
require 'pp'
pp r.by_commit if options[:log]
pp r.by_person if options[:people]
pp r.by_date if options[:date]
pp r.by_month if options[:month]

