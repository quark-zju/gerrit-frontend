require 'digest/sha1'

class Content < ActiveRecord::Base

  def self.by_content(content)
    sha1 = Digest::SHA1.hexdigest(content)
    where(:digest => sha1).first || create!(
      compressed_content: ActiveSupport::Gzip.compress(content),
      digest: sha1,
    )
  end

  def content= new_content
    @content = new_content
    self.compress_content = ActiveSupport::Gzip.compress(new_content)
    self.digest = Digest::SHA1.hexdigest(new_content)
  end

  def content
    @content ||= ActiveSupport::Gzip.decompress(compressed_content)
  end

end
