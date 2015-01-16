#!/usr/bin/env ruby
require 'gli'
require 'twitter'
require 'matrix'
require 'tf-idf-similarity'
include GLI::App
program_desc 'Who the fsck is @StartupLJackson?'

# Yes, I realize its not perfect for URL regex
URLS = /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/
# regex for handles, /cc, /ht, new lines, etc.
HANDLES_AND_ADV_TWITTER = /(@([A-Za-z0-9_]{1,15})|\/cc|\/ht|\/mt|\n)/i



flag [:key]
flag [:secret]
flag [:parody], :default_value => "startupljackson"
flag [:authors], :default_value => "hunterwalk,levie,dcurtis"

pre do |global_options,command,options,args|
  if global_options[:key].nil? || global_options[:secret].nil?
  exit_now!('Create a Twitter application here: https://apps.twitter.com/. Use consumer key and consumer token')
end
  twitter_options = {
    :consumer_key => global_options[:key],
    :consumer_secret => global_options[:secret],
  }
  $twitter ||= Twitter::REST::Client.new twitter_options
  $number_of_tweets = 1000
end

command :run do |c|
  c.action do |global_options,options,args|
    puts global_options[:parody]
    puts global_options[:authors]

    parody = global_options[:parody].strip
    guesses = global_options[:authors].split(",")

    puts "Who is #{parody}? Comparing #{guesses.size} accounts"
    corpus = [guesses + [parody]].flatten.inject({}) do |list, user|
       list[user] = tfid_doc_by_user(user)
       list
    end
    model = TfIdfSimilarity::TfIdfModel.new(corpus.values)
    puts "building a similarity matrix from term-freq docs"
    matrix = model.similarity_matrix

    results = guesses.inject({}) do |list, user|
      sim = matrix[model.document_index(corpus[user]), model.document_index(corpus[parody])]
      list[user] = sim
      list
    end
    results.sort_by{|_,v| -1*v}.each {|k,v| puts " [%.2f%%] %s" % [v*100,k]}
  end
end


def collect_first_x(list=[], max_id=nil, &block)
  response = yield(max_id)
  list += response
  list.flatten!
  if list.size > $number_of_tweets || response.last.nil?
    list.first($number_of_tweets)
  else
    collect_first_x(list, response.last.id - 1, &block)
  end
end

def recent_tweets(user)
  # Note: It might not equal exactly $number_of_tweets b/c of replies/rts..close enough
  puts "[#{user}] fetching #{$number_of_tweets} tweets"
  results = collect_first_x do |max_id|
    options = {:count => 200, :include_rts => false, :exclude_replies => true, :trim_user => true}
    options[:max_id] = max_id unless max_id.nil?
    print "."
    fetch_tweets_for(user,options)
  end
  puts ""
  results
end

def fetch_tweets_for(user,options)
  $twitter.user_timeline(user, options)
end

# remove URLs, handles, and /cc, /rt, new lines, duplicate spaces, etc.
def clean_tweets(results)
  results.first($number_of_tweets).map(&:text).join.gsub(URLS,"").gsub(HANDLES_AND_ADV_TWITTER,"").squeeze(" ")
end

#"https://github.com/djberg96/memoize"
# Simple disk basked caching of twitter API and more.
def memoize(name, file=nil)
   cache = File.open(file, 'rb'){ |io| Marshal.load(io) } rescue {}
   (class<<self; self; end).send(:define_method, name) do |*args|
      unless cache.has_key?(args)
         cache[args] = super(*args)
         File.open(file, 'wb'){ |f| Marshal.dump(cache, f) } if file
      end
      cache[args]
   end
   cache
end
memoize(:fetch_tweets_for, "cache/tweet_objs3.cache")

def tfid_doc_by_user(user)
  terms = clean_tweets(recent_tweets(user))
  puts "[#{user}] creating term frequency doc"
  TfIdfSimilarity::Document.new(terms, :id => user)
end

exit run(ARGV)