class CreateEntries < ActiveRecord::Migration[5.1]
  def change
    create_table :entries, :id => false do |t|
      t.string :id
      t.string :username
      t.text :answer

      t.timestamps
    end
  end
end
