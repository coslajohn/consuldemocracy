class AddLineWidthAndOpacityToGeozones < ActiveRecord::Migration[7.0]
  def change
    add_column :geozones, :line_width, :integer, default: 1
    add_column :geozones, :opacity, :float, default: 1.0
  end
end
