# == Schema Information
#
# Table name: revision_files
#
#  id           :integer          not null, primary key
#  revision_id  :integer          not null
#  pathname     :string(255)      not null
#  a            :text
#  b            :text
#  compressed_a :binary
#  compressed_b :binary
#

class RevisionFile < ActiveRecord::Base
  belongs_to :revision
  has_many :revision_file_comments

  alias :comments :revision_file_comments

  before_save :compress_data

  def as_json
    {
      a: a_content,
      b: b_content,
      comments: comments.as_json,
      name: pathname,
    }
  end

  def a_content
    a || ActiveSupport::Gzip.decompress(compressed_b)
  end

  def b_content
    b || ActiveSupport::Gzip.decompress(compressed_b)
  end

  def compress_data
    %w[a b].each do |x|
      if attributes[x] && !attributes["compressed_#{x}"]
        self.send "compressed_#{x}=", ActiveSupport::Gzip.compress(self.send(x))
        self.send "#{x}=", nil
      end
    end
  end
end
