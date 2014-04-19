require 'sinatra'
require 'mysql2'
require 'aws-sdk'
require 'imgkit'
require 'dotenv'

# Load environment variables
Dotenv.load

# Prepare MYSQL connection with ActionKit
@@connection = Mysql2::Client.new(host: ENV['HOST'], username: ENV['USERNAME'], password: ENV['PASSWORD'], database: ENV['DATABASE'])

# Prepare API connection with Amazon S3
@@s3_bucket = AWS::S3.new(
  :access_key_id => ENV['ACCESS_KEY_ID'],
  :secret_access_key => ENV['SECRET_ACCESS_KEY']
).buckets[ENV['BUCKET_NAME']]

# Calculate progress towards goal
def calculate_progress
  @time = Time.now
  @sanitized_page_id = params['page_id'] ? params['page_id'].gsub(/[^0-9]/,'') : 3650
  @results = params['page_id'] ? @@connection.query("SELECT COUNT(*) AS actions, SUM(o.total) AS dollars FROM core_action a LEFT JOIN core_order o ON a.id = o.action_id WHERE a.page_id = #{@sanitized_page_id || 3650}").first : {'actions' => 500, 'dollars' => 500}
  @goal = params['goal'] || 1000
  @goal_type = params['goal_type'] || 'actions'
  @progress = @results[@goal_type]
  @percent = [99, 8 + 92 * @progress.to_i / @goal.to_i].min
end

# Generate a custom progress meter using an HTML template
get '/:page_id/:goal_type/:goal/baseball_bat' do
  calculate_progress
  erb :bat_template
end

# Generate a .png from the HTML template
get '/:page_id/:goal_type/:goal/baseball_bat.png' do
  content_type 'image/png'
  calculate_progress
  object = @@s3_bucket.objects["#{@sanitized_page_id}/#{@goal_type}/#{@goal}/baseball_bat.png"]
  unless object.exists? && (Time.now - object.last_modified < 300 || object.metadata['progress'] == @progress.to_s)
    Thread.new {
    img = IMGKit.new(erb :bat_template).to_png
    object.write(img)
    object.metadata['progress'] = @progress
    }
  end
  redirect object.public_url
end

__END__

@@bat_template
  <style>
    #bat {
    background: #ff0000;
    background: -webkit-gradient(linear, left bottom, right top, color-stop(0%,#ff0000), color-stop(<%= @percent %>%,#ff0000), color-stop(<%= @percent %>%,#ffffff), color-stop(100%,#ffffff));
    background: -webkit-linear-gradient(45deg, #ff0000 0%,#ff0000 <%= @percent %>%,#ffffff <%= @percent %>%,#ffffff 100%);
    }
  </style>
  <p><img id="bat" src="<%= request.base_url %>/img/baseball_bat.png" style="background-color:#f00;"></p>
  <p><%= "#{@goal_type}: #{@progress}" %></p>
  <p>goal: <%= @goal %></p>