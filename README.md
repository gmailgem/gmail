<img alt="Gmail for Ruby" src="https://cloud.githubusercontent.com/assets/27655/5792399/fd5d076e-9f59-11e4-826c-22c311e38356.png">

[![Build Status](https://travis-ci.org/gmailgem/gmail.svg)](https://travis-ci.org/gmailgem/gmail)
[![Code Climate](https://codeclimate.com/github/gmailgem/gmail.svg)](https://codeclimate.com/github/gmailgem/gmail)
[![Gem Version](https://badge.fury.io/rb/gmail.svg)](https://rubygems.org/gems/gmail)
[![Coverage Status](https://coveralls.io/repos/gmailgem/gmail/badge.svg?branch=master&service=github&nocache=true)](https://coveralls.io/github/gmailgem/gmail?branch=master)

## Deprecation Notice

As of version 0.7.0 (Aug 19, 2018) this gem is officially deprecated and will no longer be maintained.
Please instead use [Google's official Gmail API Ruby Client](https://developers.google.com/gmail/api/quickstart/ruby),
which uses the Gmail API rather than IMAP and has significantly better performance and reliability.

## Overview

This gem is a Rubyesque interface to Google's Gmail via IMAP. Search, read and send multipart emails,
archive, mark as read/unread, delete emails, and manage labels. It's based on [Daniel Parker's ruby-gmail gem](https://github.com/dcparker/ruby-gmail).

## Reporting Issues

As of version 0.7.x, we are accepting pull requests for critical security patches only.

This gem uses the [Mail gem](https://github.com/mikel/mail) for messages, attachments, etc. Unless your issue is related to Gmail integration specifically, please refer to [RFC-5322 (email specification)](https://tools.ietf.org/html/rfc5322) and the [Mail gem](https://github.com/mikel/mail).

## Installation

You can install it easy using rubygems:

    sudo gem install gmail
    
Or install it manually:

    git clone git://github.com/gmailgem/gmail.git
    cd gmail
    rake install

gmail gem has the following dependencies (with Bundler all will be installed automatically):

* mail
* gmail_xoauth

## Version Support

* Ruby 2.0.0+ is supported.
* Ruby 1.9.3 is supported but deprecated.
* Ruby 1.8.7 users should use gmail v0.4.1

## Features

* Search emails
* Read emails (handles attachments)
* Emails: label, archive, delete, mark as read/unread/spam, star
* Manage labels
* Create and send multipart email messages in plaintext and/or html, with inline 
  images and attachments
* Utilizes Gmail's IMAP & SMTP, MIME-type detection and parses and generates 
  MIME properly.

## Basic usage

First of all require the `gmail` library.

```ruby
require 'gmail'
```

### Authenticating gmail sessions

This will let you automatically log in to your account. 

```ruby
gmail = Gmail.connect(username, password)
# play with your gmail...
gmail.logout
```

If you pass a block, the session will be passed into the block, and the session 
will be logged out after the block is executed.

```ruby
Gmail.connect(username, password) do |gmail|
  # play with your gmail...
end
```

Examples above are "quiet", it means that it will not raise any errors when 
session couldn't be started (eg. because of connection error or invalid 
authorization data). You can use connection which handles errors raising:

```ruby
Gmail.connect!(username, password)
Gmail.connect!(username, password) {|gmail| ... play with gmail ... }
```

You can also check if you are logged in at any time:

```ruby
Gmail.connect(username, password) do |gmail|
  gmail.logged_in?
end
```

### XOAuth authentication

From v0.4.0 it's possible to authenticate with your Gmail account using XOAuth
method. It's very simple:

```ruby
gmail = Gmail.connect(:xoauth, "email@domain.com", 
  :token           => 'TOKEN',
  :secret          => 'TOKEN_SECRET',
  :consumer_key    => 'CONSUMER_KEY',
  :consumer_secret => 'CONSUMER_SECRET'
)
```

```ruby
gmail = Gmail.connect(:xoauth2, 'email@domain.com', 'ACCESS_TOKEN')
```
    
For more information check out the [gmail_xoauth](https://github.com/nfo/gmail_xoauth)
gem from Nicolas Fouché.

### XOAuth2 authentication

You can use the oauth2 token to connect to Gmail. The connect method takes 3 paramaters.

```ruby
gmail = Gmail.connect(:xoauth2, "email@domain.com", "TOKEN")
```
You can use [omniauth-google-oauth2](https://github.com/zquestz/omniauth-google-oauth2) to fetch the token. Once the omniauth authorization has been completed, you'll be left with a `auth.credentials.token` you can pass in as the third paramater to `Gmail.connect`.

### Counting and gathering emails
    
Get counts for messages in the inbox:

```ruby
gmail.inbox.count
gmail.inbox.count(:unread)
gmail.inbox.count(:read)
```

Count with some criteria:

```ruby
gmail.inbox.count(:after => Date.parse("2010-02-20"), :before => Date.parse("2010-03-20"))
gmail.inbox.count(:on => Date.parse("2010-04-15"))
gmail.inbox.count(:from => "myfriend@gmail.com")
gmail.inbox.count(:to => "directlytome@gmail.com")
```

Combine flags and options:

```ruby
gmail.inbox.count(:unread, :from => "myboss@gmail.com")
```

Browsing labeled emails is similar to work with inbox.

```ruby
gmail.mailbox('Urgent').count
```

Getting messages works the same way as counting: Remember that every message in a 
conversation/thread will come as a separate message.

```ruby
gmail.inbox.emails(:unread, :before => Date.parse("2010-04-20"), :from => "myboss@gmail.com")
```

The [gm option](https://developers.google.com/gmail/imap_extensions?csw=1#extension_of_the_search_command_x-gm-raw) enables use of the Gmail search syntax.

```ruby
gmail.inbox.emails(gm: '"testing"')
```

You can also use one of aliases:

```ruby
gmail.inbox.find(...)
gmail.inbox.search(...)
gmail.inbox.mails(...)
```

Also you can manipulate each message using block style:

```ruby
gmail.inbox.find(:unread).each do |email|
  email.read!
end
```

Note: The `:before` and `:after` filters only go as far as to search for messages on the date:

```ruby
# E.g. the following will return messages between 2016-01-01 00:00:00 and 2016-04-05 00:00:00
gmail.inbox.find(
    :after => Time.parse('2016-01-01 07:50:21'),
    :before => Time.parse('2016-04-05 21:55:05')
    )
```

### Working with emails!

Any news older than 4-20, mark as read and archive it:

```ruby
gmail.inbox.find(:before => Date.parse("2010-04-20"), :from => "news@nbcnews.com").each do |email|
  email.read! # can also unread!, spam! or star!
  email.archive!
end
```

Delete emails from X:

```ruby
gmail.inbox.find(:from => "x-fiance@gmail.com").each do |email|
  email.delete!
end
```

Save all attachments from the "Faxes" label to a local folder (uses functionality from `Mail` gem):

```ruby
folder = Dir.pwd # for example
gmail.mailbox("Faxes").emails.each do |email|
  email.message.attachments.each do |f|
    File.write(File.join(folder, f.filename), f.body.decoded)
  end
end
```

You can also use `#label` method instead of `#mailbox`:

```ruby
gmail.label("Faxes").emails.each {|email| ... }
```

Save just the first attachment from the newest unread email (assuming pdf):

```ruby
email = gmail.inbox.find(:unread).first
attachment = email.attachments[0]
File.write(File.join(folder_path, attachment.filename), attachment.body.decoded)
```

Add a label to a message:

```ruby
email.label("Faxes")
```

Example above will raise error when you don't have the `Faxes` label. You can
avoid this using:

```ruby
email.label!("Faxes") # The `Faxes` label will be automatically created now
```

You can also move message to a label/mailbox:

```ruby
email.move_to("Faxes")
email.move_to!("NewLabel")
```

There are also few shortcuts to mark messages quickly:

```ruby
email.read!
email.unread!
email.spam!
email.star!
email.unstar!
```

### Managing labels

With Gmail gem you can also manage your labels. You can get list of defined 
labels:

```ruby
gmail.labels.all
```

Create new label:

```ruby
gmail.labels.new("Urgent")
gmail.labels.add("AnotherOne")
```

Remove labels:

```ruby
gmail.labels.delete("Urgent")
```

Or check if given label exists:

```ruby
gmail.labels.exists?("Urgent")     # => false
gmail.labels.exists?("AnotherOne") # => true
```

Localize label names using the LIST special-use extension flags,
:Inbox, :All, :Drafts, :Sent, :Trash, :Important, :Junk, and :Flagged

```ruby
gmail.labels.localize(:all) # => "[Gmail]\All Mail"
                            # => "[Google Mail]\All Mail"
```

### Composing and sending emails

Creating emails now uses the amazing [Mail](http://rubygems.org/gems/mail) rubygem. 
See its [documentation here](http://github.com/mikel/mail). The Ruby Gmail will 
automatically configure your Mail emails to be sent via your Gmail account's SMTP, 
so they will be in your Gmail's "Sent" folder. Also, no need to specify the "From" 
email either, because ruby-gmail will set it for you.

```ruby
gmail.deliver do
  to "email@example.com"
  subject "Having fun in Puerto Rico!"
  text_part do
    body "Text of plaintext message."
  end
  html_part do
    content_type 'text/html; charset=UTF-8'
    body "<p>Text of <em>html</em> message.</p>"
  end
  add_file "/path/to/some_image.jpg"
end
```

Or, compose the message first and send it later

```ruby
email = gmail.compose do
  to "email@example.com"
  subject "Having fun in Puerto Rico!"
  body "Spent the day on the road..."
end
email.deliver! # or: gmail.deliver(email)
```

## Troubleshooting

If you are having trouble connecting to Gmail:
* Please ensure your account is verified
* In [Gmail Security Settings](https://www.google.com/settings/security), enable access for less secure applications.
* Read [this support answer re: suspicious activity](https://support.google.com/mail/answer/78754) and try things like entering a captcha.

## Authors

#### Core Team

This project follows on Open Governance model. The Core Team is responsible for technical guidance, reviewing/merging PRs, and releases.

* Jeff Carbonella - [@jcarbo](https://github.com/jcarbo)
* Johnny Shields - [@johnnyshields](https://github.com/johnnyshields)
* Alexandre Loureiro Solleiro - [@webcracy](https://github.com/webcracy)
* Justin Grevich - [@jgrevich](https://github.com/jgrevich)
* [@bootstraponline](https://github.com/bootstraponline)
* Nathan Herald - [@myobie](https://github.com/myobie)

#### Legacy Contributors

* Kriss Kowalik - [@nu7hatch](https://github.com/nu7hatch)
* Daniel Parker - [@dcparker](https://github.com/dcparker)
* Refer to [CHANGELOG](https://github.com/gmailgem/gmail/blob/master/CHANGELOG.md) for individual contributions

## Copyright

* Copyright (c) 2015-2018 GmailGem team
* Copyright (c) 2010-2014 Kriss 'nu7hatch' Kowalik
* Copyright (c) 2009-2010 BehindLogic

Licensed under the MIT license. See [LICENSE](https://github.com/gmailgem/gmail/blob/master/LICENSE) for details.
