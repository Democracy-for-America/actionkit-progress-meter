actionkit-progress-meter
========================

Generate custom progress meters for ActionKit pages with Sinatra + [IMGKit](https://github.com/csquared/IMGKit)

Requirements:
---------------

- ruby
- sinatra
- [wkhtmltoimage](https://code.google.com/p/wkhtmltopdf/downloads/detail?name=wkhtmltoimage-0.11.0_rc1-static-amd64.tar.bz2&can=2&q=)
- Amazon S3

Set-up:
---------------

    $ gem install imgkit
    $ sudo imgkit --install-wkhtmltoimage
    $ bundle install
    # replace the example MySQL credentials in the .env file with your ActionKit MySQL credentials:
    $ mv .env.example .env
    $ ruby app.rb

Running on Heroku:
---------------

    $ heroku apps create
    $ git push heroku master
    # set up your MySQL connection & S3 credentials:
    $ heroku config:set USERNAME='username' PASSWORD='password' HOST='example.client-db.actionkit.com' DATABASE='ak_example' ACCESS_KEY_ID='s3_access_key' SECRET_ACCESS_KEY='secret_access_key' BUCKET_NAME='actionkit-progress-meter.example.com' PROVIDER='AWS'

In Action:
---------------

[http://actionkit-progress-meter.herokuapp.com/3650/dollars/40000/baseball_bat.png](http://actionkit-progress-meter.herokuapp.com/3650/dollars/40000/baseball_bat.png)

(format: http://actionkit-progress-meter.herokuapp.com/[:page_id]/[:goal_type]/[:goal]/baseball_bat.png)

`page_id` is the page_id of the ActionKit page to pull progress from.

`goal_type` is the type of goal (actions or dollars, actions being the default).

`goal` is the numerical goal for the page.