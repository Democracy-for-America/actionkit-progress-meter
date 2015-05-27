actionkit-progress-meter
========================

Generate custom progress meters for ActionKit pages with Sinatra + [IMGKit](https://github.com/csquared/IMGKit)

How it works:
---------------

This app generates progress meters via a customized HTML template, converts them to .png files, and uploads these files to Amazon S3.

Every time a progress meter is requested, the app will immediately redirect to a page's most recently archived S3 image, and if necessary, update the image via a background process.

The URL of the progress meter image for any given ActionKit page includes an MD5 hash of the page's ID & created_at timestamp, and a secret salt. This prevents anyone with an internet connection from easily determining the number of actions or donation totals for any ActionKit page hosted by your organization.

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

Adding additional templates and images:
---------------

To create the progress meter, this application uses a png image with a transparent cut-out, overlaid on top of a background which fills up as a progress meter approaches its goal.

To allow for a template to be re-used with minor variations in text, color, etc., each template may support multiple image overlays.

Templates may be added to views/templates, as .erb files.

A template is passed four variables, which may be used in generating the progress meter:

    @goal (a numeric string)
    @goal_type ('actions' or 'dollars')
    @progress (a numeric string)
    @percent (an integer)

Images may be added to public/img/[template_name]. (Each image must be contained in a sub-directory corresponding to a template.)

Example file structure:

    views
      templates
        baseball_template.erb
        soccer_template.erb
    
    public
      img
        baseball_template
          pitcher.png
          shortshop.png
        soccer_template
          goalie.png
          referee.png


Running on Heroku:
---------------

    $ heroku apps create
    $ git push heroku master
    # set up your MySQL connection, S3 credentials and other environment variables, if you're not checking the .env file into version control:
    $ heroku config:set USERNAME='username' PASSWORD='password' HOST='example.client-db.actionkit.com' DATABASE='ak_example' ACCESS_KEY_ID='s3_access_key' SECRET_ACCESS_KEY='secret_access_key' BUCKET_NAME='actionkit-progress-meter.example.com' PROVIDER='AWS'

In Action:
---------------

http://actionkit-progress-meter.herokuapp.com/504/3ecaa3e88721b5bdd60a6650dbb71018/actions/100000/bat_template/baseball_bat.png

(format: http://actionkit-progress-meter.herokuapp.com/[:page_id]/[:md5_hash]/[:goal_type]/[:goal]/[:template]/[:image].png)

`page_id` is the page_id of the ActionKit page to pull progress from.

`md5_hash` is the string returned by `Digest::MD5.new.update("#{ENV['SALT']}#{@results['created_at']}#{@sanitized_page_id}").to_s`

`goal_type` is the type of goal ("actions" or "dollars").

`goal` is the numerical goal for the page.

Hint:
---------------

To quickly look up the URL of a page's progress meter with the valid MD5 hash, simply visit http://actionkit-progress-meter.herokuapp.com/lookup (Password-protected via Basic HTTP Authentication. Credentials may be set by editing the .env file.)
