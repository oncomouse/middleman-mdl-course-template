###
# Compass
###
set :markdown_engine, :kramdown
set :markdown, :fenced_code_blocks => true,
				 :autolink => true, 
				 :smartypants => true,
				 :footnotes => true,
				 :superscript => true

set :haml, { :ugly => false, :format => :html5 }

# Figure out the course's file name to set deploy path
$course_tag = File.basename Dir.pwd

# Base path for all courses:
config[:build_http_prefix] = "/courses/#{$course_tag}"

### Change everything before #{config[:build_http_prefix]} to the location you will be deploying these courses.
#   If your website is http://foobar.com/me and /courses is created in that directory,
#   change http://your-server.com to http://foobar.com/me
###
config[:site_deploy_root] = "http://your-server.com#{config[:build_http_prefix]}"

# Proxy the course info YAML file:
ready do
	proxy "/#{$course_tag}.yml", "/course.yml" if "/#{@course_tag}.yml" != "/course.yml"
	ignore "/course.yml"
end

["red","pink","purple","deep_purple","indigo","blue","light_blue","cyan","teal","green","light_green","lime","yellow","amber","orange","deep_orange","brown","blue_grey","grey"].each do |primary_color|
	["red","pink","purple","deep_purple","indigo","blue","light_blue","cyan","teal","green","light_green","lime","yellow","amber","orange","deep_orange"].each do |secondary_color|
		next if primary_color == secondary_color
		proxy "/stylesheets/app.#{primary_color}-#{secondary_color}.css", "/stylesheets/app.css", locals: {primary_color: primary_color, secondary_color: secondary_color}, ignore: true
	end
end

###
# Helpers
###

helpers do
	def rot13(string)
		string.tr "A-Za-z", "N-ZA-Mn-za-m"
	end
 
	# HTML encodes ASCII chars a-z, useful for obfuscating
	# an email address from spiders and spammers
	def html_obfuscate(string)
		output_array = []
		lower = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
		upper = %w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
		char_array = string.split('')
		char_array.each do |char|	
			output = lower.index(char) + 97 if lower.include?(char)
			output = upper.index(char) + 65 if upper.include?(char)
			if output
				output_array << "&##{output};"
			else 
				output_array << char
			end
		end
		return output_array.join
	end
	
	def js_antispam_email_link(email, linktext=email)
		user, domain = email.split('@')
		user	 = html_obfuscate(user)
		domain = html_obfuscate(domain)
		# if linktext wasn't specified, throw encoded email address builder into js document.write statement
		linktext = "'+'#{user}'+'@'+'#{domain}'+'" if linktext == email 
		rot13_encoded_email = rot13(email) # obfuscate email address as rot13
		#out =	"<noscript>#{linktext}<br/><small>#{user}(at)#{domain}</small></noscript>\n" # js disabled browsers see this
		out = "<script language='javascript'>\n"
		out += "	<!--\n"
		out += "		string = '#{rot13_encoded_email}'.replace(/[a-zA-Z]/g, function(c){ return String.fromCharCode((c <= 'Z' ? 90 : 122) >= (c = c.charCodeAt(0) + 13) ? c : c - 26);});\n"
		out += "		document.write('<a href='+'ma'+'il'+'to:'+ string +'>#{linktext}</a>'); \n"
		out += "	//-->\n"
		out += "</script>\n"
		return out
	end
end

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

## Build-specific configuration
configure :build do

	ignore "stylesheets/*"
	
	activate :minify_html
	activate :minify_javascript, inline: true
	activate :minify_css, inline: true
	
	set :http_prefix, config[:build_http_prefix]
end

activate :deploy do |deploy|
	deploy.deploy_method = :rsync
	deploy.user = "you"
	deploy.host = "you.your-server.com"
	deploy.path = "~/#{config[:build_http_prefix]}"
end