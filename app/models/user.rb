# coding: utf-8  
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::SoftDelete
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  field :login
  field :name
  field :email
  field :location
  field :bio
  field :website
  field :verified, :type => Boolean, :default => false
  field :state, :type => Integer, :default => 1
  field :tagline  
  field :replies_count, :type => Integer, :default => 0  
  
  has_many :topics, :dependent => :destroy  
  has_many :notes
  has_many :replies
	embeds_many :authorizations
    
  attr_accessor :password_confirmation
  attr_accessible :remember_me,:login, :name, :location, :website, :bio, :tagline, :email, :password, :password_confirmation
  
  validates_presence_of :login, :name  
  validates_uniqueness_of :login, :name
  
  has_and_belongs_to_many :following_nodes, :class_name => 'Node', :inverse_of => :followers
  has_and_belongs_to_many :following, :class_name => 'User', :inverse_of => :followers
  has_and_belongs_to_many :followers, :class_name => 'User', :inverse_of => :following

  def password_required?
    (authorizations.empty? || !password.blank?) && super  
  end
  
  before_create :default_value_for_create
  def default_value_for_create
    self.state = STATE[:normal]
  end
  
  # 注册邮件提醒
  after_create :send_welcome_mail
  def send_welcome_mail
    m = UserMailer.create_welcome(self)
    Thread.new { m.deliver }
	rescue => e
		# logger.error { e }
  end

  STATE = {
    :normal => 1,
    # 屏蔽
    :blocked => 2
  }

  def self.cached_count
    return Rails.cache.fetch("users/count",:expires_in => 1.hours) do
      self.count
    end
  end

	def self.create_from_hash(auth)  
		user = User.new
		user.name = auth["user_info"]["name"]  
		user.email = auth['user_info']['email']
		user.save(false)
		user.reset_persistence_token! #set persistence_token else sessions will not be created
		user
  end  
end
