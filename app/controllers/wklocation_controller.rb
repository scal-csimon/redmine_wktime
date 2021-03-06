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

class WklocationController < WkbaseController
  unloadable
  menu_item :wkcrmenumeration
  include WktimeHelper
  include WkdocumentHelper
  helper :wkdocument
  helper :attachments
  before_action :require_login
  before_action :check_perm_and_redirect, :only => [:index, :edit, :update, :destroy]
	accept_api_auth :getlocations

  def index
		sort_init 'name', 'asc'
		sort_update 'name' => "name",
					'type' => "#{WkCrmEnumeration.table_name}.name",
					'city' => "#{WkAddress.table_name}.city",
					'state' => "#{WkAddress.table_name}.state"

		set_filter_session
		locationName = session[controller_name].try(:[], :location_name)
		locationType =  session[controller_name].try(:[], :location_type)
		wklocation = WkLocation.all

		if locationType.present? && locationType.to_i != 0
			wklocation = wklocation.where(:location_type_id => locationType.to_i)
		end

		if locationName.present?
			wklocation = wklocation.where("LOWER(wk_locations.name) like LOWER(?) ", "%#{locationName}%")
		end

		wklocation = wklocation.joins("LEFT JOIN wk_addresses ON wk_locations.address_id = wk_addresses.id")
			.joins("LEFT JOIN wk_crm_enumerations ON wk_locations.location_type_id = wk_crm_enumerations.id")
		formPagination(wklocation.reorder(sort_clause))
  end
  
  def edit
		@locEntry = nil
		unless params[:location_id].blank?
			@locEntry = WkLocation.find(params[:location_id])
		end
  end
  
  def update
		errorMsg = nil
		if params[:location_id].blank? || params[:location_id].to_i == 0
			locationObj = WkLocation.new
		else
		  locationObj = WkLocation.find(params[:location_id].to_i)
		end
		locationObj.name = params[:location_name]
		locationObj.location_type_id = params[:location_type]
		locationObj.is_default = params[:defaultValue]
		locationObj.is_main = params[:defaultMain]
		locationObj.attachment_id = params[:attachment_id].present? ? params[:attachment_id] : nil
		unless locationObj.valid?
			errorMsg = errorMsg.blank? ? locationObj.errors.full_messages.join("<br>") : locationObj.errors.full_messages.join("<br>") + "<br/>" + errorMsg
		end
		if errorMsg.blank?
			addrId = updateAddress
			locationObj.address_id = addrId if addrId.present?
			locationObj.save
			params[:container_id] = locationObj.id
			errorMsg = save_attachments() if params[:attachments].present?
		end
		if errorMsg.blank?
		    redirect_to :controller => controller_name,:action => 'index' , :tab => controller_name
		    flash[:notice] = l(:notice_successful_update)
		else
			flash[:error] = errorMsg 
		    redirect_to :controller => controller_name,:action => 'edit', :location_id => locationObj.id
		end
  end
  
  def destroy
		location = WkLocation.find(params[:location_id].to_i)
		if location.destroy
			flash[:notice] = l(:notice_successful_delete)
		else
			flash[:error] = location.errors.full_messages.join("<br>")
		end
		redirect_back_or_default :action => 'index', :tab => params[:tab]
  end

  def set_filter_session
		if params[:searchlist] == controller_name
			session[controller_name] = Hash.new if session[controller_name].nil?
			filters = [:location_name, :location_type, :show_on_map]
			filters.each do |param|
				if params[param].blank? && session[controller_name].try(:[], param).present?
					session[controller_name].delete(param)
				elsif params[param].present?
					session[controller_name][param] = params[param]
				end
			end
		end
	end
	
	def check_perm_and_redirect
		unless User.current.admin? || hasSettingPerm
			render_403
			return false
		end
	end
	
	def formPagination(entries)
		@entry_count = entries.count
        setLimitAndOffset()
		@locationObj = entries.limit(@limit).offset(@offset)
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

	def getlocations
		wklocations = WkLocation.order(name: :asc)
		locations = []
		locations = wklocations.map { |loc| { value: loc.id, label: loc.name }}
		render json: locations
	end
end
