module PeopleHelper
  EDIT_FIELD = %{<div class="form-row">
<span class="form-label"><label for="%s">%s</label></span>
<span class="form-field">%s</span>
</div>}

  def photo_path(person = nil)
    if person.photo.blank?
      image_path('head.png')
    else
      #url_for(:action => 'show', :id => person.id, :format => 'jpeg')
      person_path(person, :photo => person.photo, :format => 'jpeg')
    end
  end
  
  def p_photo(person, edit = nil)
    image_tag(person.photo.blank? ?
#        'head.png' : url_for(:action => 'show', :id => person,
#        :photo => person.photo, :format => 'jpeg'),
        'head.png' : person_path(person, :photo => person.photo, :format => 'jpeg'),
      :id => dom_id(person, :photo), 
      :class => edit ? 'photo edit' : 'photo')
  end

  def pe_photo(person)
    p_photo(person, true)
  end

  def p_email(email, klass = '')
    e = h email.email
    "<div class='email #{klass}'>
<span class='type'>#{email.location}</span>
<a href='mailto:#{e}'><span class='value'>#{e}</span></a></div>"
  end

  def p_phone(phone, klass = '')
    "<div class='tel #{klass}'>
<span class='type'>#{phone.location}, #{phone.capability}</span>
<span class='value'>#{h phone.number}</span></div>"
  end

  def p_address(address, klass = '')
    # FIXME: add <!-- span class='region'>NRW</span -->
    "<div class='adr #{klass}'>
<span class='type'>#{ address.location }</span>
<span class='value'>
<span class='street-address'>#{h address.street }</span>
<span class='postal-code'>#{h address.zip }</span>
<span class='locality'> #{h address.city }</span>
<span class='country-name'>#{h address.country }</span>
</span>
</div>"
  end

  def p_name(person)
    "<div class='fn'>#{h person.display_name}</div>"
  end

  def p_organization(person)
    person.organization.blank? ? '' :
      %{<span class="org">#{h person.organization}</span>}
  end

  def pe_organization(form)
    return p_organization(form.object) if form.object.link
    EDIT_FIELD % ['org', 'Organization', form.text_field(:organization,
        :size => 23, :class => 'clue', :title => 'Organization')]
  end

  def p_title(person)
    person.title.blank? ? '' :
      %{<span class="title">#{h person.title}</span>}
  end

  def pe_title(form)
    return p_title(form.object) if form.object.link
    EDIT_FIELD % ['title', 'Title', form.text_field(:title, :size => 16,
        :class => 'clue', :title => 'Title')]
  end

  def p_url(person)
    person.url.blank? ? '' :
      %{<span class="url">#{h person.url}</span>}
  end

  def pe_url(form)
    return p_url(form.object) if form.object.link
    EDIT_FIELD % ['url', 'URL', form.text_field(:url, :size => 23,
        :class => 'clue', :title => 'Url')]
  end

  def p_nickname(person)
    person.nickname.blank? ? '' :
      %{<span class="nick">#{h person.nickname}</span>}
  end

  def pe_nickname(form)
    return p_nickname(form.object) if form.object.link
    EDIT_FIELD % ['nickname', 'Nickname', form.text_field(:nickname, 
        :size => 23, :class => 'clue', :title => 'Nickname')]
  end

  def p_birthday(person)
    person.birthday.blank? ? '' :
      %{<span class="birthday">#{h person.birthday.to_s(:presentable_date)}</span>}
  end

  def pe_birthday(form)
    return p_birthday(form.object) if form.object.link
    # FIXME: prompt does not work yet, but should soon. Fix is already there
    EDIT_FIELD % ['bday', 'Birthday', form.date_select(:birthday,
        :title => _('Birthday'), :order => [:day, :month, :year],
        :start_year => 1900, :use_month_numbers => true, :prompt => true)]
  end

  def remove_link(fields)
    delete = hidden = ''
    # only for existing records
    if fields.object.new_record?
      link_to_function("",
        "$(this).up('.#{fields.object.class.name.underscore}').remove()",
        :class => 'remove')
    else
      fields.hidden_field(:_delete) +
        link_to_function("",
        "$(this).up('.#{fields.object.class.name.underscore}').hide();\
$(this).previous().value = '1'", :class => 'remove')
    end
  end

  # These use the current date, but they could be lots easier.
  # Maybe just keep a global counter which starts at 10 or so.
  # That would be good enough if we only build 1 new record in the controller.
  #
  # And this of course is only needed because Ryan's example uses JS to add new
  # records. If you just build a new one in the controller this is all unnecessary.

  def add_link(name, form, obj_name)
    field = ''
    form.fields_for obj_name, obj_name.to_s.classify.constantize.new do |f|
      field = render :partial => 'people/' + obj_name.to_s.singularize, :object => f
    end
    link_to_function name, :class => 'add' do |page|
      page << %{
        var new_id = "new_" + new Date().getTime();
        $('fieldset_#{obj_name}').insert({ bottom: "#{ escape_javascript field }"\.replace(/new_\\d+/g, new_id) });
      }
    end
  end

  # taken from http://github.com/ryanb/complex-form-examples/tree/deep
  # das problem ist, dass neue Objekte immer new_phone[0] heissen.
  # Hat man zwei davon, wird das erste vom zweiten überschrieben.
  # Deswegen ersetzt die JS Funktion insert_fields() [in application.js]
  # [0] durch einen eindeutigen Wert...

  def remove_child_link(f)
    f.hidden_field(:_delete) + 
      link_to_function(image_tag("/images/minus.png"),
                       "remove_fields(this)", :class=>'minus')
  end

  def add_child_link(f, method)
    fields = new_child_fields(f, method, :form_builder_local => method.to_s.singularize.to_sym)
    link_to_function(image_tag("/images/plus.png"),
      h("insert_fields(this, \"#{method}\", \"#{escape_javascript(fields)}\")"),
      :class => 'plus'
    )
  end

  def new_child_fields(form_builder, method, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(method).klass.new
    options[:partial] ||= method.to_s.singularize
    options[:form_builder_local] ||= :f
    form_builder.fields_for(method, options[:object], :child_index => "new_#{method}") do |f|
      render(:partial => options[:partial], :locals => { options[:form_builder_local] => f })
    end
  end


  # used in form_many to print details in edit or just print
  def pe_many_collection_details(details, form)
    details.each_with_index do |detail_to_ids,idx|
      detail = detail_to_ids[0]
      detail_name_plural ||= detail.class.to_s.tableize
      detail_name        ||= detail_name_plural.singularize
      if detail.person.user == current_user
        form.fields_for "#{detail_name_plural}_attributes[]", detail,
          :index => "new_#{idx}"  do |form_detail|
          concat(render(:partial => 'people/'+detail_name, :object => form_detail))
        end
      else
        concat(self.send('p_'+detail_name, detail))
      end
    end
  end

  def pe_many_detail(people, detail, form)
    obj_save = form.object
    people[detail].each_with_index do |person_to_ids,idx|
      form.object = person_to_ids[0]
      concat(self.send('pe_'+detail.to_s, form))
      unless form.object.link
        concat(link_to_function(image_tag("button_remove.png",
            :alt => _('remove')), "$(this).up('.form-row').remove()"))
      end
    end
    form.object = obj_save
  end

end
