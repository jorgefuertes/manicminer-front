# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'livereload' do
  watch(%r{app/stylesheets/.+\.sass}) do
	"/stylesheets/front.css"
  end
  # APP
  watch(%r{app/views/.+\.(erb|haml|slim)$})
  watch(%r{app/helpers/.+\.rb})
  # Admin
  watch(%r{admin/views/.+\.(erb|haml|slim)$})
  # Aux
  watch(%r{public/.+\.(css|js|html)})
  watch(%r{(app|admin|config)/locale/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|js|html))).*}) { |m| "/assets/#{m[3]}" }
end
