# cloudstack-client

A ruby CloudStack API client by Nik Wolfgramm (<nik.wolfgramm@swisstxt.ch>) based on knife-cloudstack by Ryan Holmes (<rholmes@edmunds.com>), KC Braunschweig (<kcbraunschweig@gmail.com>)

See [CloudStack API reference](http://download.cloud.com/releases/3.0.3/api_3.0.3/TOC_Domain_Admin.html)

## Installation
 - make sure you have a working ruby environment
 - install bundler `gem install bundler`
 - execute `bundle install` in order to install dependencies
 - copy the example config file `cp config/cloudstack.example.yml config/cloudstack.yml` and edit the CloudStack keys

## Usage 
To play see the ClouStack API client in action and execute play-cloudstack:
`ruby examples/play-cloudstack.rb`

***

Copyright (c) 2012, Nik Wolfgramm
