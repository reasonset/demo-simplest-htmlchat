#!/usr/bin/ruby
require 'erb'
require 'webrick'
include WEBrick

CHAT_HTML = File.read("template.erb")
Encoding.default_external = "UTF-8"

def esc(str)
  str && str.gsub(/&#([0-9]+);/) {|i| [$1.to_i].pack("U") }.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
end

srv = HTTPServer.new( { :BindAddress => '127.0.0.1', :Port => 10080 } )
srv.mount_proc "/" do |req, res|
  File.open("sessionlock.lck", "w") do |f|
    f.flock(File::LOCK_EX)
    chat = nil
    begin
      begin
        chat = Marshal.load File.open("chat.log")
      rescue 
        chat = []
      end
      cgi = req.query
      chat.unshift({name: esc(cgi["name"]), timestamp: Time.now.strftime("%y-%m-%d %T"), chat: esc(cgi["chat"])&.[](0, 1024)})
      chat = chat[0,30]
      File.open("chat.log", "w") {|f| Marshal.dump chat, f } 
      File.open("chat.html", "w") {|f| f.puts ERB.new(CHAT_HTML).result(binding)}
    ensure
      f.flock(File::LOCK_UN)
    end
  end
  res.status = 204
end

srv.start