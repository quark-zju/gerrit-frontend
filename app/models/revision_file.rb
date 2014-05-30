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
  belongs_to :a_content, class_name: 'Content'
  belongs_to :b_content, class_name: 'Content'
  has_many :revision_file_comments, :dependent => :delete_all

  alias :comments :revision_file_comments

  def as_json
    {
      a: a,
      b: b,
      comments: comments.as_json,
      name: pathname,
    }
  end

  %w[a b].each do |prefix|
    content_varialbe_name = "@#{prefix}_content"

    define_method prefix do
      content = instance_variable_get content_varialbe_name
      if content.nil?
        content = send("#{prefix}_content_id") && send("#{prefix}_content").content
        instance_variable_set content_varialbe_name, content
      end
      content
    end

    define_method "#{prefix}=" do |content|
      instance_variable_set content_varialbe_name, content
      if content
        send "#{prefix}_content_id=", Content.by_content(content).id
      else
        send "#{prefix}_content_id=", nil
      end
    end
  end

end
