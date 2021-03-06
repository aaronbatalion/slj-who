#!/usr/bin/env ruby
require 'gli'
require 'twitter'
require 'matrix'
require 'tf-idf-similarity'
require 'yaml'
include GLI::App
program_desc 'Who the fsck is @StartupLJackson?'

# Yes, I realize its not perfect for URL regex
URLS = /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/
# regex for handles, /cc, /ht, new lines, etc.
HANDLES_AND_ADV_TWITTER = /(@([A-Za-z0-9_]{1,15})|\/cc|\/ht|\/mt|\n)/i

pre do |global_options,command,options,args|
  config = YAML.load_file(".twitter.yml") rescue {}
  secret, key = options[:secret] || config[:secret], options[:key] || config[:key]
  if secret.nil? || key.nil?
    exit_now!('Create a Twitter application here: https://apps.twitter.com/. Use consumer key and consumer token with:
./slj-who config --key MY-KEY --secret MY-SECRET')
  end
  $twitter ||= Twitter::REST::Client.new :consumer_key => key, :consumer_secret => secret
  $number_of_tweets = 400
end

command :config do |c|
  c.desc 'Set the key/secret from apps.twitter.com'
  c.flag [:key], :type => String
  c.flag [:secret], :type => String
  c.action do |global_options,options,args|
    key = options[:key]
    secret = options[:secret]
    File.open(".twitter.yml","w") {|f| f << {:key => key, :secret => secret}.to_yaml}
  end
end

command :run do |c|
  c.desc ""
  c.flag [:parody], :default_value => "startupljackson"
  c.flag [:authors], :default_value => "dcurtis,aaronbatalion,levie"
  c.action do |global_options,options,args|
    parody = options[:parody].strip
    guesses = options[:authors].split(",")

    puts "Who is #{parody}? Comparing #{guesses.size} accounts"
    puts "="*60
    corpus = [guesses + [parody]].flatten.inject({}) do |list, user|
       list[user] = tfid_doc_by_user(user)
       list
    end
    model = TfIdfSimilarity::TfIdfModel.new(corpus.values)
    matrix = model.similarity_matrix

    results = guesses.inject({}) do |list, user|
      sim = matrix[model.document_index(corpus[user]), model.document_index(corpus[parody])]
      list[user] = sim
      list
    end
    puts "="*60
    puts "Based on TF-IDF Text Analysis, we think #{parody} is:"
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
  print "[#{user}] fetching #{$number_of_tweets} tweets: "
  results = collect_first_x do |max_id|
    options = {:count => 200, :include_rts => false, :exclude_replies => true, :trim_user => true}
    options[:max_id] = max_id unless max_id.nil?
    print "."
    $twitter.user_timeline(user, options)
  end
  puts ""
  results
end

# remove URLs, handles, and /cc, /rt, new lines, duplicate spaces, etc.
def clean_tweets(results)
  results.first($number_of_tweets).map(&:text).join.gsub(URLS,"").gsub(HANDLES_AND_ADV_TWITTER,"").squeeze(" ")
end

def tfid_doc_by_user(user)
  terms = clean_tweets(recent_tweets(user))
  puts "[#{user}] creating term frequency doc"
  TfIdfSimilarity::Document.new(terms, :id => user)
end

exit run(ARGV)