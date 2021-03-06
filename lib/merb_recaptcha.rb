require 'openssl'
require 'base64'
require 'cgi'
require 'net/http'
require 'net/https'

module MerbRecaptcha

  module ViewHelper

    def get_captcha(options={})
      k = MerbRecaptcha::Client.new(options[:rcc_pub] || RCC_PUB, options[:rcc_priv] || RCC_PRIV, options[:ssl] || false)
      r = k.get_challenge(session[:rcc_err] || '', options)
      session[:rcc_err]=''
      r
    end
    def mail_hide(address, contents=nil)
      contents = truncate(address,10) if contents.nil?
      k = MerbRecaptcha::MHClient.new(MH_PUB, MH_PRIV)
      enciphered = k.encrypt(address)
      uri = "http://mailhide.recaptcha.net/d?k=#{MH_PUB}&c=#{enciphered}"
      t =<<-EOF
      <a href="#{uri}"
      onclick="window.open('#{uri}', '', 'toolbar=0,scrollbars=0,location=0,statusbar=0,menubar=0,resizable=0,width=500,height=300'); return false;" title="Reveal this e-mail address">#{contents}</a>
    EOF
    end

  end

  module AppHelper
    private
    def validate_recap(p, errors, options = {})
      rcc=MerbRecaptcha::Client.new(options[:rcc_pub] || RCC_PUB, options[:rcc_priv] || RCC_PRIV)
      res = rcc.validate(request.remote_ip, p[:recaptcha_challenge_field], p[:recaptcha_response_field], errors)
      session[:rcc_err]=rcc.last_error

      res
    end
  end

  class MHClient
    def initialize(pubkey, privkey)
      @pubkey=pubkey
      @privkey=privkey
      @host='mailhide.recaptcha.net'
    end
    def encrypt(string)
      padded = pad(string)
      iv="\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00"
      cipher=OpenSSL::Cipher::Cipher.new("AES-128-CBC")
      binkey = @privkey.unpack('a2'*16).map{|x| x.hex}.pack('c'*16)
      cipher.encrypt
      cipher.key=binkey
      cipher.iv=iv
      ciphertext = []
      cipher.padding=0
      ciphertext = cipher.update(padded)
      ciphertext << cipher.final() rescue nil 
      Base64.encode64(ciphertext).strip.gsub(/\+/, '-').gsub(/\//, '_').gsub(/\n/,'')
    end
    def pad(str)
      l= 16-(str.length%16)
      l.times do
        str<< l
      end
      str
    end
  end

  class Client
    def initialize(pubkey, privkey, ssl=false)
      @pubkey = pubkey
      @privkey=privkey
      @host = ssl ? 'api-secure.recaptcha.net':'api.recaptcha.net'
      @vhost = 'api-verify.recaptcha.net'
      @proto = ssl ? 'https' : 'http'
      @ssl = ssl
      @last_error=nil
    end

    def get_challenge(error='', options={})
      s=''
      if options[:options]
        s << "<script type=\"text/javascript\">\nvar RecaptchaOptions = { "
        options[:options].each do |k,v|
          val = (v.class == Fixnum) ? "#{v}" : "\"#{v}\""
          s << "#{k} : #{val}, "
        end
        s.sub!(/, $/, '};')
        s << "\n</script>\n"
      end
      errslug = (error.empty?||error==nil||error=="success") ? '' :  "&error=#{CGI.escape(error)}"
      s <<<<-EOF
      <script type="text/javascript" src="#{@proto}://#{@host}/challenge?k=#{CGI.escape(@pubkey)}#{errslug}"> </script>
      <noscript>
      <iframe src="#{@proto}://#{@host}/noscript?k=#{CGI.escape(@pubkey)}#{errslug}"
      height="300" width="500" frameborder="0"></iframe><br>
      <textarea name="recaptcha_challenge_field" rows="3" cols="40">
      </textarea>
      <input type="hidden" name="recaptcha_response_field" 
      value="manual_challenge">
      </noscript>
      EOF
    end

    def last_error
      @last_error
    end

    def validate(remoteip, challenge, response, errors)
      msg = "Captcha failed."
      return true if  %w(0.0.0.0 127.0.0.1).include?(remoteip)
      unless response and challenge
        errors.add_to_base(msg)
        return false
      end
      proxy_host, proxy_port = nil, nil
      proxy_host, proxy_port = ENV['proxy_host'].split(':')  if ENV.has_key?('proxy_host')
      http = Net::HTTP::Proxy(proxy_host, proxy_port).start(@vhost)
      path='/verify'
      data = "privatekey=#{CGI.escape(@privkey)}&remoteip=#{CGI.escape(remoteip)}&challenge=#{CGI.escape(challenge)}&response=#{CGI.escape(response)}"
      resp, data = http.post(path, data, {'Content-Type'=>'application/x-www-form-urlencoded'})
      response = data.split
      result = response[0].chomp
      @last_error=response[1].chomp
      errors.add_to_base(msg) if  result != 'true'
      result == 'true' 
    end
  end
end
