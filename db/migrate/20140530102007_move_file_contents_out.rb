class RevisionFile < ActiveRecord::Base
  def a_content
    a || (compressed_a && ActiveSupport::Gzip.decompress(compressed_b))
  end

  def b_content
    b || (compressed_b && ActiveSupport::Gzip.decompress(compressed_b))
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

class MoveFileContentsOut < ActiveRecord::Migration
  def up
    change_table :revision_files do |t|
      t.references :a_content
      t.references :b_content
    end

    RevisionFile.transaction do
      RevisionFile.find_each do |f|
        a = f.a_content
        b = f.b_content
        f.a_content_id = Content.by_content(a).id if a
        f.b_content_id = Content.by_content(b).id if b
        f.save
      end
    end

    %w[a b compressed_a compressed_b].each do |name|
      remove_column :revision_files, name
    end
  end
end
