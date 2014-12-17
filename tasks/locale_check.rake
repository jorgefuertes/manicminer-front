# locale_check.rake

namespace :locale do
    desc 'Check locales keys'
    task :check => :environment do
        logger.level = 4

        shell.say "> Loading en locale..."
        en = YAML::load(File.open("#{Padrino.root}/app/locale/en.yml"))["en"]
        shell.say "> Loading es locale..."
        es = YAML::load(File.open("#{Padrino.root}/app/locale/es.yml"))["es"]

        shell.say "> Comparing en with es..."
        checkYamlHash(en, es)
        shell.say "> Comparing es with en..."
        checkYamlHash(es, en)

        shell.say "Done"
    end # End task

    def checkYamlHash(one, two, context = [])
        one.each do |key, value_one|
            unless two.key?(key)
              shell.say "Missing key ", :red
              shell.say "#{key} ", :yellow
              shell.say "at "
              shell.say "second ", :cyan
              shell.say "locale, path "
              shell.say context.join('.'), :magenta
              next
            end

            if value_one.is_a?(Hash)
                checkYamlHash(value_one, two[key], (context + [key]))
                next
            end
        end
    end

end # End namespace
