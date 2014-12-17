# url_helper.rb

ManicminerPool::App.helpers do
    def base_url
        return request.base_url
    end

    def getLinkedTweet(text)
        text = text.gsub( %r{http://[^\s<]+} ) do |url|
            if url[/(?:png|jpe?g|gif|svg)$/]
                "<img src='#{url}' />"
            else
                "<a class=\"url\" href='#{url}'>#{url}</a>"
            end
        end

        text = text.gsub(%r{\@[^\s<.:,]+}) do |user|
            "<a class=\"user\" href=\"http://twitter.com/#{user}\">#{user}</a>"
        end

        text = text.gsub(%r{^RT}) do |rt|
            "<span class=\"rt\">RT</span>"
        end

        return text
    end
end
