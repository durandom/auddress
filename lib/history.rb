class History

  @@user_id = nil
  
  def self.user=(user)
    if user.class == User
      @@user_id = user.id
    elsif user.class == Integer
      @@user_id = user
    end
  end

#  CONTEXT.each do |c|
#    class_eval(<<-EOS)
#      def self.#{c}(message, *args)
#         args.last.[:context] = '#{c}'
#         self.add(message, *args)
#      end
#    EOS
#  end

  def self.sync(message, opts = {})
    opts[:context] = 'sync'
    self.add(message, opts)
  end

  def self.add(message = '', *args)
    o = args.extract_options!
    Event.new(
      :message => message,
      :when => DateTime.now,
      :ref => o[:ref],
      :context => o[:context],
      :user_id => @@user_id
    ).save
  end
end