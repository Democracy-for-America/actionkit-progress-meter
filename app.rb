require 'sinatra'
require 'mysql2'
require 'aws-sdk'
require 'imgkit'
require 'dotenv'
require 'digest/md5'

# Load environment variables
Dotenv.load

# Prepare MYSQL connection with ActionKit
@@connection = Mysql2::Client.new(host: ENV['AK_HOST'], username: ENV['AK_USERNAME'], password: ENV['AK_PASSWORD'], database: ENV['AK_DATABASE'])

# Prepare API connection with Amazon S3
@@s3_bucket = AWS::S3.new(
  access_key_id: ENV['S3_ACCESS_KEY_ID'],
  secret_access_key: ENV['S3_SECRET_ACCESS_KEY']
).buckets[ENV['S3_BUCKET_NAME']]

helpers do
  # Basic Auth helpers
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized"
  end
  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV['BASIC_AUTH_USER'], ENV['BASIC_AUTH_PASSWORD']]
  end

  # Check validity of hash
  def valid_hash?
    unless params['hash'] == @valid_hash
      halt 404, "Not found"
    end
  end

  # Calculate progress towards goal
  def calculate_progress
    @time = Time.now
    @sanitized_page_id = params['page_id'].gsub(/[^0-9]/,'')
    @results = @@connection.query("SELECT p.created_at, COUNT(*) AS actions, SUM(o.total) AS dollars FROM core_page p LEFT JOIN core_action a ON p.id = a.page_id LEFT JOIN core_order o ON a.id = o.action_id WHERE p.id = #{@sanitized_page_id}").first
    @goal = params['goal'].gsub(/[^0-9]/,'')
    @goal_type = ( ['actions','dollars'].include?(params['goal_type']) ? params['goal_type'] : 'actions' )
    @progress = @results[@goal_type]
    @percent = [99, @progress.to_i / @goal.to_i].min
    @template = ['templates', params['template']].join('/').to_sym
    @valid_hash = Digest::MD5.new.update("#{ENV['SALT']}#{@results['created_at']}#{@sanitized_page_id}#{params['template']}#{params['image']}").to_s
  end
end

# Render an image of an HTML template, and upload to S3
def render_image_and_save_to_s3(object)
  dimensions = IO.read("public/img/#{params['template']}/#{params['image']}.png")[0x10..0x18].unpack('NN')
  img = IMGKit.new(erb(@template), width: dimensions[0], height: dimensions[1]).to_png
  object.write(img)
end

get '/lookup' do
  protected!
  files = Dir.glob('public/img/*/*')
  @templates = files.map { |x| x.split('/')[2] }.uniq
  @images = files.map { |x| x.split('/')[3].gsub('.png','') }.uniq
  erb :'admin/lookup'
end

# Display the path for a page's progress meter
get '/show' do
  protected!
  calculate_progress
  erb :'admin/show'
end

# Generate a .png from the HTML template
get '/:page_id/:hash/:goal_type/:goal/:template/:image.png' do
  content_type 'image/png'
  calculate_progress
  valid_hash?
  object = @@s3_bucket.objects["#{@sanitized_page_id}/#{@goal_type}/#{@goal}/#{params['template']}/#{params['image']}.png"]
  case
  when object.exists? == false
    # When the image doesn't exist, create it immediately
    render_image_and_save_to_s3(object)
    object.metadata['progress'] = @progress
  when Time.now - object.last_modified > 300 && object.metadata['progress'] != @progress.to_s
    # When the time since the image has last been updated is over 300 seconds
    # and the goal progress has changed, update the image via a background process
    object.metadata['progress'] = @progress
    Thread.new { render_image_and_save_to_s3(object) }
  end
  redirect object.public_url
end

# Generate a custom progress meter using an HTML template
get '/:page_id/:hash/:goal_type/:goal/:template/:image' do
  dimensions = IO.read("public/img/#{params['template']}/#{params['image']}.png")[0x10..0x18].unpack('NN')
  calculate_progress
  valid_hash?
  erb @template
end
