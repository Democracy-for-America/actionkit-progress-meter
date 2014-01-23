require 'sinatra'
require 'mysql2'
require 'imgkit'
require 'dotenv'

Dotenv.load

@@connection = Mysql2::Client.new(host: ENV['HOST'], username: ENV['USERNAME'], password: ENV['PASSWORD'], database: ENV['DATABASE'])

before do
  @results = params[:page_id] ? @@connection.query("SELECT COUNT(*) AS actions, SUM(o.total) AS dollars FROM core_action a LEFT JOIN core_order o ON a.id = o.action_id WHERE a.page_id = #{params[:page_id] || 3650}").first : {'actions' => 500, 'dollars' => 500}
  @goal = params['goal'] || 1000
  @goal_type = params['goal_type'] || 'actions'
  @progress = @results[@goal_type]
  @percent = [99, 8 + 92 * @progress.to_i / @goal.to_i].min
end

get '/baseball_bat' do
  erb :bat_template
end

get '/baseball_bat.png' do
  content_type 'image/png'
  @kit = IMGKit.new(erb :bat_template).to_png
end

__END__

@@bat_template
  <style>
    #bat {
    background: #ff0000;
    background: -moz-linear-gradient(35deg, #ff0000 0%, #ff0000 <%= @percent %>%, #ffffff <%= @percent %>%, #ffffff 100%);
    background: -webkit-gradient(linear, left bottom, right top, color-stop(0%,#ff0000), color-stop(<%= @percent %>%,#ff0000), color-stop(<%= @percent %>%,#ffffff), color-stop(100%,#ffffff));
    background: -webkit-linear-gradient(35deg, #ff0000 0%,#ff0000 <%= @percent %>%,#ffffff <%= @percent %>%,#ffffff 100%);
    background: -o-linear-gradient(35deg, #ff0000 0%,#ff0000 <%= @percent %>%,#ffffff <%= @percent %>%,#ffffff 100%);
    background: -ms-linear-gradient(35deg, #ff0000 0%,#ff0000 <%= @percent %>%,#ffffff <%= @percent %>%,#ffffff 100%);
    background: linear-gradient(35deg, #ff0000 0%,#ff0000 <%= @percent %>%,#ffffff <%= @percent %>%,#ffffff 100%);
    filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ff0000', endColorstr='#ffffff',GradientType=1 );
    }
  </style>
  <p><img id="bat" src="<%= request.base_url %>/img/baseball_bat.png" style="background-color:#f00;"></p>
  <p><%= @goal_type %>: <%= @results[@goal_type].to_i %></p>
  <p>goal: <%= @goal %></p>
  <p><%= @kit %>