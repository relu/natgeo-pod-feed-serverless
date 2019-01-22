require 'json'
require 'rss'
require 'open-uri'
require 'aws-sdk-s3'

POD_COLLECTION_ID = 'fd5444cc-4777-4438-b9d4-5085c0564b44'

def generate_feed(event:, context:)
  url = "https://relay.nationalgeographic.com/proxy/distribution/feed/v1?format=json&content_type=featured_image&fields=image,uri&collection=#{POD_COLLECTION_ID}"

  feed = open(url, 'apiauth-apiuser' => ENV['API_USER'], 'apiauth-apikey' => ENV['API_KEY'])
  json = JSON.parse(feed.read)

  rss = RSS::Maker.make("atom") do |maker|
    maker.channel.author = "National Geographic"
    maker.channel.updated = Time.now.to_s
    maker.channel.about = "https://www.nationalgeographic.com/photography/photo-of-the-day/"
    maker.channel.title = "National Geographic: Photo of the day"
    maker.channel.icon = "https://www.nationalgeographic.com/etc/designs/platform/refresh/images/favicon.ico"

    json.each do |image|
      maker.items.new_item do |item|
        item.link = image['pointer']['uri']
        item.title = image['title']
        item.summary = image['short_abstract']
        item.author = image['image']['credit']
        item.pubDate = image['publication_datetime']
        item.updated = image['last_modified_datetime']
      end
    end
  end

  s3 = Aws::S3::Resource.new(region: ENV['REGION'])
  obj = s3.bucket(ENV['BUCKET']).object('feed.xml')
  obj.put(body: rss.to_s, acl: 'public-read')

  puts 'ok'
end
