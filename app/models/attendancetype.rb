class Attendancetype < ActiveRecord::Base
  @@atype_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 10.minutes, :race_condition_ttl => 5)
  attr_accessible :absent, :color, :description, :display_column, :name, :display_order, :default_type, :default_inactive, :default_created, :grade_type
  
  default_scope order(:display_order)
  
  has_many :userattendances, :inverse_of => :attendancetype, :dependent => :restrict
  
  def self.default
    RequestStore.store[:atype_default] ||= fetchall.select { |aid, a| a.default_type }.values.first || getall.first
  end
  
  def self.inactive_default
    RequestStore.store[:atype_inactive] ||= fetchall.select { |aid, a| a.default_inactive }.values.first || self.default
  end
  
  def self.created_default
    RequestStore.store[:atype_created] ||= fetchall.select { |aid, a| a.default_created }.values.first || self.default
  end
  
  def self.fetchall
    RequestStore.store[:atype_all] ||= @@atype_cache.fetch('all') do
      ret = {}
      Attendancetype.all.each do |atype|
        ret[atype.id] = atype
      end
      ret
    end
  end
  
  def self.fetch(atype_id)
    fetchall[atype_id]
  end
  
  def self.getall
    RequestStore.store[:atype_sorted] ||= fetchall.values.sort_by! &:display_order
  end

  def self.find_by_name(name)
    self.getall.select{|a| a.name == name}.first
  end

  def grade_as_present?
    grade_type == 0
  end

  def grade_as_tardy?
    grade_type == 1
  end

  def grade_as_absent?
    grade_type == 2
  end
end
