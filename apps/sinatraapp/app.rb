require 'sinatra'
require 'mongo'
require 'json/ext'
require_relative 'db/config'

before '/me' do
	content_type :txt
end

['/things', '/thing/*', '/remove/*', '/new'].each do |path|
	before path do
		content_type :json
	end
end

not_found do
	"404 - nothing here, go 'way"
end

helpers do
	def object_by_id val
		begin
			BSON::ObjectId.from_string(val)
		rescue BSON::ObjectId::Invalid
			nil
		end
	end

	def document_by_id id
		#id = object_by_id(id) #if String === id
		id = id.to_i
		if id.nil?
			{}.to_json
		else
			document = settings.mongo_db.find(:docid => id).to_a.first
			(document || {}).to_json
		end
	end

	def latest_addition
		l_id = settings.mongo_db.find().sort({_id:-1}).limit(1).to_a[0]['docid']
		if l_id.nil?
			0
		else
			l_id
		end
	end
end

get '/' do
    "Welcome #{request.user_agent}! The time is: #{Time.now}. Pizza, Pizza in #{settings.bind}!"
end

get '/me' do
	request.env.map { |e| e.to_s + "\n" }
end

get '/things/?' do
	settings.mongo_db.find.to_a.to_json
end

get '/thing/:id/?' do
	document_by_id(params[:id])
end	

post '/new/?' do
	db = settings.mongo_db
	params = JSON.parse(request.body.read)
	latest_id = latest_addition
	new_id = latest_id + 1
	params['docid'] = new_id
	result = db.insert_one params
	db.find(:_id => result.inserted_id).to_a.first.to_json
end

delete '/remove/:id' do
	db = settings.mongo_db
	id = id.to_i
	doc = db.find(:docid => id)
	if !doc.to_a.first.nil?
		doc.find_one_and_delete
		{:success => true}.to_json
	else
		{:success => false}.to_json
	end
end




    

