# Who the Fsck is SLJ?


*SLJ-Who* is a silly command line tool to guess who is more likely to be
the author of your favorite parody twitter account.

## In Jan 2014, I said [this](https://twitter.com/abatalion/status/424094146173730816):
![abatalion tweet](https://s3.amazonaws.com/f.cl.ly/items/0h3h1M3m0l0C2u1f3F3Z/Screen%20Shot%202015-01-16%20at%2012.42.56%20PM.jpg)

## Then @endtwist in Jan 2015 actually did [the work](https://twitter.com/endtwist/status/554358608985866240):
![@endtwist tweet](https://s3.amazonaws.com/f.cl.ly/items/0O430L1F2X2o3i2X3H3r/Screen%20Shot%202015-01-16%20at%2012.43.08%20PM.jpg)

## And @techcrunch later [here](http://techcrunch.com/2015/01/11/maybe-its-arrington/):
![techcrunch post](https://s3.amazonaws.com/f.cl.ly/items/3x3S121q1A1i273G0y1X/Screen%20Shot%202015-01-16%20at%2012.44.19%20PM.jpg)

I applied a similiar approach using [TF*IDF](http://en.wikipedia.org/wiki/Tf%E2%80%93idf)
and also cleaned the data a bit before classification.
Changes results a bit...

# Installation

You'll need twitter api credentials.
Go to [https://apps.twitter.com/app/new](https://apps.twitter.com/app/new)
Create an application.
     ![create app](https://s3.amazonaws.com/f.cl.ly/items/302d3a2h0T343Y0F2H0h/Screen%20Shot%202015-01-16%20at%201.06.19%20PM.jpg)

Under "Keys and Access Tokens", grab your Consumer Secret & Consumer Key.
     ![secret and key](https://s3.amazonaws.com/f.cl.ly/items/2Y2I3q1K0P2i3G2x2j2j/keys.jpg.jpg)


    gem install bundler
    git clone https://github.com/aaronbatalion/slj-who
    cd slj-who && bundle install


# Examples

    ./slj-who.rb --key=THIS-IS-YOUR-KEY --secret=THIS-IS-YOUR-SECRET --authors=dcurtis,abatalion,levie --parody=startupljackson run


Produces output like:

    Who is startupljackson? Comparing 3 accounts
    ================================================================================
    [dcurtis] fetching 1000 tweets: .............
    [dcurtis] creating term frequency doc
    [abatalion] fetching 1000 tweets: .................
    [abatalion] creating term frequency doc
    [levie] fetching 1000 tweets: ......
    [levie] creating term frequency doc
    [startupljackson] fetching 1000 tweets: ..................
    [startupljackson] creating term frequency doc
    building a similarity matrix from term-freq docs
     [48.60%] levie
     [47.04%] abatalion
     [45.65%] dcurtis

# TODO
  lots... feel free to fork.