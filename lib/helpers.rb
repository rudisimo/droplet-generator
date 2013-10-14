# -*- mode: ruby -*-
# vi: set ft=ruby :

require "erb"
require "net/https"
require "uri"
require "rubygems"
require "json"
require "sqlite3"

class Configuration
  attr_accessor :vm_box, :vm_box_url, :vm_memory, :vm_hostname, :vm_timezone, :vm_http_port,
                :do_client_id, :do_api_key, :do_image, :do_region, :do_size,
                :ssh_username, :ssh_private_key,
                :db, :id, :file
  def initialize(file)
    @file = file
    begin
      @db = SQLite3::Database.new file
      @db.results_as_hash = true
      build
      locate
      restore
    rescue SQLite3::Exception => e
      @db = nil
    end
  end
  def build
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS env (
        id INTEGER PRIMARY KEY,
        created VARCHAR(30),
        updated VARCHAR(30),
        vm_box VARCHAR(30),
        vm_box_url VARCHAR(255),
        vm_memory INT,
        vm_hostname VARCHAR(255),
        vm_timezone VARCHAR(50),
        vm_http_port INT,
        do_client_id VARCHAR(40),
        do_api_key VARCHAR(40),
        do_image VARCHAR(30),
        do_region VARCHAR(30),
        do_size VARCHAR(30),
        ssh_username VARCHAR(50),
        ssh_private_key VARCHAR(255)
      );
    SQL
  end
  def locate
    @id = @db.get_first_value <<-SQL
      SELECT id FROM env LIMIT 1
    SQL
  end
  def valid?
    return !@db.nil? ? true : false
  end
  def configured?
    return !@id.nil? ? true : false
  end
  def restore
    if valid?
      sql_query = <<-SQL
        SELECT * FROM env WHERE id = :id
      SQL
      row = @db.get_first_row sql_query, @id
      if !row.nil?
        @vm_box = row["vm_box"] unless row["vm_box"].nil?
        @vm_box_url = row["vm_box_url"] unless row["vm_box_url"].nil?
        @vm_memory = row["vm_memory"] unless row["vm_memory"].nil?
        @vm_hostname = row["vm_hostname"] unless row["vm_hostname"].nil?
        @vm_timezone = row["vm_timezone"] unless row["vm_timezone"].nil?
        @vm_http_port = row["vm_http_port"] unless row["vm_http_port"].nil?
        @do_client_id = row["do_client_id"] unless row["do_client_id"].nil?
        @do_api_key = row["do_api_key"] unless row["do_api_key"].nil?
        @do_image = row["do_image"] unless row["do_image"].nil?
        @do_region = row["do_region"] unless row["do_region"].nil?
        @do_size = row["do_size"] unless row["do_size"].nil?
        @ssh_private_key = row["ssh_private_key"] unless row["ssh_private_key"].nil?
        @ssh_username = row["ssh_username"] unless row["ssh_username"].nil?
      end
    end
  end
  def store
    if valid?
      sql_date = DateTime.now.to_s
      sql_query = @id.nil? ? create : update
      @db.prepare(sql_query) do |stm|
        stm.bind_param("id", @id)
        stm.bind_param("created", sql_date) if @id.nil?
        stm.bind_param("updated", sql_date)
        stm.bind_param("vm_box", @vm_box)
        stm.bind_param("vm_box_url", @vm_box_url)
        stm.bind_param("vm_memory", @vm_memory)
        stm.bind_param("vm_hostname", @vm_hostname)
        stm.bind_param("vm_timezone", @vm_timezone)
        stm.bind_param("vm_http_port", @vm_http_port)
        stm.bind_param("do_client_id", @do_client_id)
        stm.bind_param("do_api_key", @do_api_key)
        stm.bind_param("do_image", @do_image)
        stm.bind_param("do_region", @do_region)
        stm.bind_param("do_size", @do_size)
        stm.bind_param("ssh_private_key", @ssh_private_key)
        stm.bind_param("ssh_username", @ssh_username)
        stm.execute
      end
      locate
    end
  end
  def create
    return <<-SQL
      INSERT INTO env
        VALUES (
          :id,
          :created,
          :updated,
          :vm_box,
          :vm_box_url,
          :vm_memory,
          :vm_hostname,
          :vm_timezone,
          :vm_http_port,
          :do_client_id,
          :do_api_key,
          :do_image,
          :do_region,
          :do_size,
          :ssh_private_key
          :ssh_username
        )
    SQL
  end
  def update
    return <<-SQL
      UPDATE env
        SET
          updated = :updated,
          vm_box = :vm_box,
          vm_box_url = :vm_box_url,
          vm_memory = :vm_memory,
          vm_hostname = :vm_hostname,
          vm_timezone = :vm_timezone,
          vm_http_port = :vm_http_port,
          do_client_id = :do_client_id,
          do_api_key = :do_api_key,
          do_image = :do_image,
          do_region = :do_region,
          do_size = :do_size,
          ssh_private_key = :ssh_private_key,
          ssh_username = :ssh_username
        WHERE id = :id
    SQL
  end
end

class Generator
  attr_accessor :config, :template
  def initialize(config, template)
    @config = config
    @template = template
  end
  def render
    ERB.new(File.read(@template)).result(binding)
  end
  def save(file)
    File.open(file, "w+") do |f|
      f.write(render)
    end
  end
end

class DigitalOcean
  attr_accessor :client_id, :api_key
  def initialize(client_id, api_key)
    @client_id = client_id
    @api_key = api_key
  end
  def parse(verb)
    json = get(verb)
    parsed = JSON.parse(json)
    return parsed[verb]
  end
  def get(verb)
    url = "https://api.digitalocean.com/#{verb}/?client_id=#{@client_id}&api_key=#{@api_key}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    return response.body
  end
end
