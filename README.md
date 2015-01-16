# Who the Fsck is SLJ?


*SLJ-Who* is a silly command line tool to guess who is more likely to be
the author of your favorite parody twitter account.

In Jan 2014, I said this:
https://twitter.com/abatalion/status/424094146173730816

Then @endtwist in Jan 2015 actually did the work:
https://twitter.com/endtwist/status/554358608985866240

and @techcrunch later here:
http://techcrunch.com/2015/01/11/maybe-its-arrington/

I applied a similiar approach but accounted for edge cases of RTs, Replies, etc.

# Installation

You'll need twitter api credentials. Annoying, I know.
Go here: https://apps.twitter.com/
Create an application.
Under "Keys and Access Tokens", grab your Consumer Secret & Consumer Key.

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
