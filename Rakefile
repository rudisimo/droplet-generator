# -*- mode: ruby -*-
# vi: set ft=ruby :

require "lib/helpers"
require "rubygems"
require "highline/import"
require "rainbow"

create_dirs = {
  "tmpdir"  => File.join(File.dirname(__FILE__), "files", "tmp"),
  "env"     => File.join(File.dirname(__FILE__), "files", "env"),
  "docroot" => File.join(File.dirname(__FILE__), "files", "www"),
}
download_urls = {
  "dotfiles" => "https://github.com/rudisimo/dotfiles.git"
}
temporary_files = {
  "dotfiles" => File.join(File.dirname(__FILE__), "files", "tmp", "dotfiles"),
}
output_files = {
  "defaultrole" => File.join(File.dirname(__FILE__), "manifests", "default.pp"),
  "dotfiles"    => File.join(File.dirname(__FILE__), "files", "dot"),
  "database"    => File.join(File.dirname(__FILE__), "files", "env", "config.db"),
  "bootstrap"   => File.join(File.dirname(__FILE__), "files", "env", "bootstrap.sh"),
  "vagrant"     => File.join(File.dirname(__FILE__), "Vagrantfile"),
}
template_files = {
  "defaultrole" => File.join(File.dirname(__FILE__), "templates", "roles", "default.pp.erb"),
  "bootstrap"   => File.join(File.dirname(__FILE__), "templates", "bootstrap.sh.erb"),
  "vagrant"     => File.join(File.dirname(__FILE__), "templates", "Vagrantfile.erb"),
}
available_boxes = {
  "lucid32"   => "http://files.vagrantup.com/lucid32.box",
  "lucid64"   => "http://files.vagrantup.com/lucid64.box",
  "precise32" => "http://files.vagrantup.com/precise32.box",
  "precise64" => "http://files.vagrantup.com/precise64.box",
}
supported_boxes = {
  "Ubuntu 10.04 x32" => "lucid32",
  "Ubuntu 10.04 x64" => "lucid64",
  "Ubuntu 12.04 x32" => "precise32",
  "Ubuntu 12.04 x64" => "precise64",
}

# create dependencies
create_dirs.each do |t, dir|
  if !File.exist?(dir)
    puts "Creating: " + dir.color(:yellow)
    FileUtils.mkdir_p(dir)
  end
end

# load the configuration
config = Configuration.new(output_files["database"])

desc "Initialize your environment"
task :init, :rebuild do |t, args|
  task(:configure).invoke(args[:rebuild])
  task(:generate).invoke(args[:rebuild])
end

desc "Configure your environment"
task :configure, :rebuild do |t, args|
  args.with_defaults(:rebuild => nil)
  if config.valid?
    config.do_client_id = ask("DigitalOcean Client ID?") { |q|
      q.default = args[:rebuild].nil? ? nil : config.do_client_id
    } unless !config.do_client_id.nil? and args[:rebuild].nil?
    config.do_api_key = ask("DigitalOcean API Key?") { |q|
      q.default = args[:rebuild].nil? ? nil : config.do_api_key
    } unless !config.do_api_key.nil? and args[:rebuild].nil?
    config.do_image = ask("DigitalOcean Droplet Image?") { |q|
      q.default = args[:rebuild].nil? ? "Ubuntu 12.04 x64" : config.do_image
    } unless !config.do_image.nil? and args[:rebuild].nil?
    config.do_region = ask("DigitalOcean Droplet Region?") { |q|
      q.default = args[:rebuild].nil? ? "New York 2" : config.do_region
    } unless !config.do_region.nil? and args[:rebuild].nil?
    config.do_size = ask("DigitalOcean Droplet Size?") { |q|
      q.default = args[:rebuild].nil? ? "512MB" : config.do_size
    } unless !config.do_size.nil? and args[:rebuild].nil?
    config.vm_hostname = ask("Server Hostname?") { |q|
      q.default = args[:rebuild].nil? ? "mydroplet.local" : config.vm_hostname
    } unless !config.vm_hostname.nil? and args[:rebuild].nil?
    config.vm_timezone = ask("Server Time Zone?") { |q|
      q.default = args[:rebuild].nil? ? %x( systemsetup -gettimezone ).slice(11..-1).strip : config.vm_timezone
    } unless !config.vm_timezone.nil? and args[:rebuild].nil?
    config.ssh_username = ask("SSH Username?") { |q|
      q.default = args[:rebuild].nil? ? "vagrant" : config.ssh_username
    } unless !config.ssh_username.nil? and args[:rebuild].nil?
    config.ssh_private_key = ask("SSH Private Key?") { |q|
      q.default = args[:rebuild].nil? ? "~/.ssh/id_rsa" : config.ssh_private_key
    } unless !config.ssh_private_key.nil? and args[:rebuild].nil?
    config.vm_http_port = ask("VM HTTP Tunnel?") { |q|
      q.default = args[:rebuild].nil? ? "8080" : config.vm_http_port.to_s
    } unless !config.vm_http_port.nil? and args[:rebuild].nil?
    config.vm_box = supported_boxes[config.do_image] if supported_boxes.has_key? config.do_image
    config.vm_box_url = available_boxes[config.vm_box] if available_boxes.has_key? config.vm_box
    config.vm_memory = config.do_size.sub(/[A-Z]+/, "")
    config.store
  else
    puts "You must initialize you environment first: " + "rake init".color(:red)
  end
end

desc "Generate your environment"
task :generate, :rebuild do |t, args|
  args.with_defaults(:rebuild => nil)
  if config.configured?
    template_files.each do |k, template|
      if !File.exist?(output_files[k]) or !args[:rebuild].nil?
        puts "Generating: " + k.color(:yellow)
        vagrant_gen = Generator.new(config, template)
        vagrant_gen.save(output_files[k])
      end
    end
    if !File.exist?(output_files["dotfiles"]) or !args[:rebuild].nil?
      puts "Downloading: " + "dotfiles".color(:yellow)
      FileUtils.mkdir_p(output_files["dotfiles"])
      Kernel.system("git clone -q #{download_urls["dotfiles"]} #{temporary_files["dotfiles"]}")
      Kernel.system("rsync -huzrq --delete --exclude=.git --exclude=.gitignore --exclude=bootstrap.sh --exclude=README.md --exclude=LICENSE-MIT.txt #{temporary_files["dotfiles"]}/ #{output_files["dotfiles"]}/")
      FileUtils.rm_rf(temporary_files["dotfiles"])
    end
  else
    puts "You must configure you environment first: " + "rake configure".color(:red)
  end
end

desc "Display all DigitialOcean droplet information"
task :droplets => [:images, :sizes, :regions]

desc "Display DigitalOcean droplet images"
task :images do
  yes = "\\u2713".gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
  no = "\\u00D7".gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
  if !config.do_client_id.nil? and !config.do_api_key.nil?
    puts "[" + "Images".color(:green) + "]"
    api = DigitalOcean.new(config.do_client_id, config.do_api_key)
    images = api.parse "images"
    images.each do |image|
      is_supported = supported_boxes.has_key?(image["name"]) ? yes.color(:green) : no.color(:red)
      puts "  [  " + is_supported + "  ] #{image["name"]}"
    end
  else
    puts "You must configure you environment first: " + "rake configure".color(:red)
  end
end

desc "Display DigitalOcean droplet regions"
task :regions do
  if !config.do_client_id.nil? and !config.do_api_key.nil?
    puts "[" + "Regions".color(:green) + "]"
    api = DigitalOcean.new(config.do_client_id, config.do_api_key)
    regions = api.parse "regions"
    regions.each do |region|
      puts "  [" + "#{region["slug"].rjust(5)}".color(:green) + "] #{region["name"]}"
    end
  else
    puts "You must configure you environment first: " + "rake configure".color(:red)
  end
end

desc "Display DigitalOcean droplet sizes"
task :sizes do
  if !config.do_client_id.nil? and !config.do_api_key.nil?
    puts "[" + "Sizes".color(:green) + "]"
    api = DigitalOcean.new(config.do_client_id, config.do_api_key)
    sizes = api.parse "sizes"
    sizes.each do |size|
      puts "  [" + "$#{size["cost_per_month"].slice(0..-3)}".rjust(5).color(:green) + "] #{size["name"]}"
    end
  else
    puts "You must configure you environment first: " + "rake configure".color(:red)
  end
end

desc "Check environment configuration [default]"
task :check do
  if config.configured?
    puts "Environment configuration:"
    puts "[" + "Digital Ocean".color(:green) + "]"
    puts "  Client ID -> [" + config.do_client_id.color(:yellow) + "]" unless config.do_client_id.nil?
    puts "  API Key   -> [" + config.do_api_key.color(:yellow) + "]" unless config.do_api_key.nil?
    puts "[" + "Droplet".color(:green) + "]"
    puts "  Image     -> [" + config.do_image.color(:yellow) + "]" unless config.do_image.nil?
    puts "  Size      -> [" + config.do_size.color(:yellow) + "]" unless config.do_size.nil?
    puts "  Region    -> [" + config.do_region.color(:yellow) + "]" unless config.do_region.nil?
    puts "[" + "VirtualBox".color(:green) + "]"
    puts "  Box       -> [" + config.vm_box.color(:yellow) + "]" unless config.vm_box.nil?
    puts "  Box URL   -> [" + config.vm_box_url.color(:yellow) + "]" unless config.vm_box_url.nil?
    puts "[" + "Server".color(:green) + "]"
    puts "  Hostname  -> [" + config.vm_hostname.color(:yellow) + "]" unless config.vm_hostname.nil?
    puts "  Username  -> [" + config.ssh_username.color(:yellow) + "]" unless config.ssh_username.nil?
    puts "  SSH Key   -> [" + config.ssh_private_key.color(:yellow) + "]" unless config.ssh_private_key.nil?
    puts "Rebuild your configuration with: " + "rake configure[1]".color(:red)
    puts "Rebuild your environment with:   " + "rake generate[1]".color(:red)
  else
    puts "You must initialize you environment first: " + "rake init".color(:red)
  end
end

task :default => [:check]
