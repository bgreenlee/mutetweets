# Mute Tweets

[Mute Tweets](http://mutetweets.com) is a Twitter service that allows you to 
temporarily unfollow someone who's being too noisy, refollowing them after a 
given period of time.

Before you can start using the service, you need to connect Mute Tweets to your 
Twitter account so that it can unfollow and refollow on your behalf. Don't 
worry--Mute Tweets won't ever do anything else to your Twitter account, and 
you can revoke access any time.

## Usage

To mute someone, just tweet:

    [d] @mutetweets <@noisyperson> <length of time>

`<length of time>` follows the format `<number><unit>`, where `<unit>` is one of "m" (minutes), "h" (hours), or "d" (days).

## Examples

    @mutetweets @scobleizer 3h  # mute @scobleizer for 3 hours
    d mutetweets @scobleizer 3h # send a direct message instead
                                # (To send direct messages, follow 
                                # mutetweets--it will follow you back.)

## Options

    -v or -verbose   get direct messages when your mute starts and ends

Example:

    d mutetweets @scobleizer 3h -verbose

## Notes & Issues

### Don't you be annoying, either.

Keep in mind that the person you muted will get 
a "...is now following you on Twitter" message when the mute expires (unless 
they've turned notifications off), and if you don't use a direct message, the 
person will also see it in their mention stream. Because of this, please use 
sparingly (if you're muting someone a lot, maybe you shouldn't be following 
them).

### What? I can't hear you.

If your tweets are protected, you have to follow mutetweets first.

## Help!

If you have an questions or problems, send an email to <support@mutetweets.com>.