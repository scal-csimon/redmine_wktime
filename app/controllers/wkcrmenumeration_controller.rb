# ERPmine - ERP for service industry
# Copyright (C) 2011-2020  Adhi software pvt ltd
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class WkcrmenumerationController < WkbaseController
  unloadable
  include WktimeHelper
  before_action :require_login
  before_action :check_perm_and_redirect, :only => [:index, :edit, :update, :destroy]
    
  accept_api_auth :getCrmEnumerations

    def index
		sort_init 'type', 'asc'
		sort_update 'type' => "enum_type",
					'name' => "name",
					'position' => "position"

		set_filter_session
		enumName = session[controller_name].try(:[], :enumname)
		enumType =  session[controller_name].try(:[], :enumType)
		wkcrmenum = nil
		if !enumName.blank? &&  !enumType.blank?
			wkcrmenum = WkCrmEnumeration.where(:enum_type => enumType).where("LOWER(name) like LOWER(?)", "%#{enumName}%")
		elsif enumName.blank? &&  !enumType.blank? 
			wkcrmenum = WkCrmEnumeration.where(:enum_type => enumType)
		elsif !enumName.blank? &&  enumType.blank?
			wkcrmenum = WkCrmEnumeration.where("LOWER(name) like LOWER(?)", "%#{enumName}%")
		else
			wkcrmenum = WkCrmEnumeration.all
		end	
		formPagination(wkcrmenum.reorder(sort_clause))
    end
  
    def edit
	@enumEntry = nil
	unless params[:enum_id].blank?
		@enumEntry = WkCrmEnumeration.find(params[:enum_id].to_i)
	end
  end
  
  def update
	wkcrmenumeration = nil 
	unless params[:enum_id].blank?
		wkcrmenumeration = WkCrmEnumeration.find(params[:enum_id].to_i)
	else
		wkcrmenumeration = WkCrmEnumeration.new
	end
	wkcrmenumeration.name = params[:enumname]
	wkcrmenumeration.position = params[:enumPosition]
	wkcrmenumeration.active = params[:enumActive]
	wkcrmenumeration.enum_type = params[:enumType]
	wkcrmenumeration.is_default = params[:enumDefaultValue]
	if wkcrmenumeration.valid?	
		wkcrmenumeration.save
		redirect_to :controller => 'wkcrmenumeration',:action => 'index' , :tab => 'wkcrmenumeration'
		flash[:notice] = l(:notice_successful_update)
	else
		flash[:error] = wkcrmenumeration.errors.full_messages.join("<br>")
		redirect_to :controller => 'wkcrmenumeration',:action => 'edit'
	end
  end
  
    def set_filter_session
		if params[:searchlist] == controller_name
			session[controller_name] = Hash.new if session[controller_name].nil?
			filters = [:enumname, :enumType]
			filters.each do |param|
				if params[param].blank? && session[controller_name].try(:[], param).present?
					session[controller_name].delete(param)
				elsif params[param].present?
					session[controller_name][param] = params[param]
				end
			end
		end
    end
	
	def formPagination(entries)
		@entry_count = entries.count
        setLimitAndOffset()
		@crmenum = entries.limit(@limit).offset(@offset)
	end
	
	def setLimitAndOffset		
		if api_request?
			@offset, @limit = api_offset_and_limit
			if !params[:limit].blank?
				@limit = params[:limit]
			end
			if !params[:offset].blank?
				@offset = params[:offset]
			end
		else
			@entry_pages = Paginator.new @entry_count, per_page_option, params['page']
			@limit = @entry_pages.per_page
			@offset = @entry_pages.offset
		end	
	end
	
	def destroy
		WkCrmEnumeration.find(params[:enum_id].to_i).destroy
		
		flash[:notice] = l(:notice_successful_delete)
		redirect_back_or_default :action => 'index', :tab => params[:tab]
	end
	
	def check_perm_and_redirect
		unless User.current.admin? || hasSettingPerm
			render_403
			return false
		end
	end

	def getCrmEnumerations
		if params[:enum_type]
			wkcrmenums = WkCrmEnumeration.where(enum_type: params[:enum_type], active: true)
				.order(enum_type: :asc, position: :asc, name: :asc)
			enums = []
			enums = wkcrmenums.map{ |enum| { value: enum.id, label: enum.name }}
			render json: enums
		else
			render_403
		end
	end
end
