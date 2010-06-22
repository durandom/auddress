## This is for i18n and l10n

namespace :i18n do
desc "Update pot/po files."
task :updatepo do
  require 'gettext/utils'
  GetText.update_pofiles("audress",
    Dir.glob("{lib,app/views,app/controllers}/**/*.{rb,rhtml,erb}"),
    "Audress 0.0")
end

desc "Create mo-files"
task :makemo do
  require 'gettext/utils'
  # GetText.create_mofiles(true)
  GetText.create_mofiles(true, "po", "locale")  # This is for "Ruby on Rails".
end
end