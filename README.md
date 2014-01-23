actionkit-progress-meter
========================

Generate custom progress meters for ActionKit pages with Sinatra + [IMGKit](https://github.com/csquared/IMGKit)

Requirements:
---------------
- ruby
- sinatra
- [wkhtmltoimage](https://code.google.com/p/wkhtmltopdf/downloads/detail?name=wkhtmltoimage-0.11.0_rc1-static-amd64.tar.bz2&can=2&q=)

Set-up:
---------------

    $ gem install imgkit
    $ sudo imgkit --install-wkhtmltoimage
    $ bundle install
    $ mv .env.example .env
    # replace the example MySQL credentials in the .env file with your ActionKit MySQL credentials
    $ ruby app.rb

Running on Heroku:
---------------
    $ heroku apps:create
    $ git push heroku master
    # set up your MySQL connection:
    $ heroku config:set USERNAME='username' PASSWORD='password' HOST='example.client-db.actionkit.com' DATABASE='ak_example'

In Action:
---------------
    http://actionkit-progress-meter.herokuapp.com/baseball_bat.png?page_id=3650&goal_type=dollars&goal=40000

`page_id` is the page_id of the ActionKit page to pull progress from.

`goal_type` is the type of goal (actions or dollars, actions being the default).

`goal` is the numerical goal for the page.
