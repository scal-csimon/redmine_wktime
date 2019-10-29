class WkleaverequestController < WkbaseController
  menu_item :wkattendance
  include WkleaverequestHelper
	include WkpayrollHelper
  include WksurveyHelper

  def index
    sort_init 'start_date', 'desc'
		sort_update 'user_name' => "CONCAT(users.firstname, users.lastname)",
                'leave_type' => "issues.subject",
                'start_date' => "start_date",
                'end_date' => "end_date",
                'status' => "wk_statuses.status"
    set_filter_session
    getUsersAndGroups
    lveReqEntires = WkLeaveReq.get_all
    lveReqEntires = lveReqEntires.leaveReqSupervisor if isSupervisor && !validateERPPermission("ADM_ERP")
    lveReqEntires = lveReqEntires.leaveReqUser unless isSupervisor || validateERPPermission("ADM_ERP")

    lveReqEntires = lveReqEntires.leaveType(session[controller_name][:leave_type]) if session[controller_name].try(:[], :leave_type).present?
    lveReqEntires = lveReqEntires.userGroup(session[controller_name][:group_id]) if session[controller_name].try(:[], :group_id).present? && session[controller_name].try(:[], :group_id) != "0"
    lveReqEntires = lveReqEntires.groupUser(session[controller_name][:user_id]) if session[controller_name].try(:[], :user_id).present? && session[controller_name].try(:[], :user_id) != "0"
    lveReqEntires = lveReqEntires.leaveReqStatus(session[controller_name][:status]) if session[controller_name].try(:[], :status).present?
    
    lveReqEntires = lveReqEntires.reorder(sort_clause)
    @leave_count = lveReqEntires.length
    @leave_pages = Paginator.new @leave_count, per_page_option, params['page']
    @leaveReqEntires = lveReqEntires.order("user_id ASC, start_date DESC").limit(@leave_pages.per_page).offset(@leave_pages.offset).to_a
  end

  def edit
    if params[:id].present?
      @leaveReqEntry = WkLeaveReq.getEntry(params[:id])
    else
      @leaveReqEntry = nil
    end
    isCurrentUser = @leaveReqEntry.blank? || @leaveReqEntry.user_id == User.current.id
    @leaveReqStatus = @leaveReqEntry.present? ? @leaveReqEntry.try(:status) : ''
    @readonly = ['C', 'R', 'A'].include?(@leaveReqStatus) || (@leaveReqStatus == 'S' && isCurrentUser) || 
      (!isCurrentUser && ['N'].include?(@leaveReqStatus))
  end

  def save
    user = User.current
    newEntry = params[:lveReqID].blank?
    leaveReq = newEntry ? WkLeaveReq.new : WkLeaveReq.find(params[:lveReqID])
    leaveReq.user_id = user.id if newEntry
    leaveReq.leave_type_id = params[:leave_type_id] if newEntry
    leaveReq.start_date = params[:start_date] if params[:start_date].present?
    leaveReq.end_date = params[:end_date] if params[:end_date].present?
    leaveReq.leave_reasons = params[:leave_reasons] if params[:leave_reasons].present?

    lveReqStatus = 'S'
    params.each do |param, val|
      lveReqStatus = param.split('_').last if param.include?("submit_")
    end
    wkstatus = [{status_for_type: "WkLeaveReq", status: lveReqStatus, status_date: Time.now, status_by_id: user.id}]
    leaveReq.wkstatus_attributes = wkstatus if leaveReq.wkstatus.blank? || leaveReq.wkstatus.last.status != status

    if leaveReq.save
      leaveReq = WkLeaveReq.getEntry(leaveReq.id)
      isUser = user.id == leaveReq.user_id
      status = getLeaveStatus[leaveReq.status]
      if (leaveReq.status == 'S' && isUser) 
        email_id = leaveReq.supervisor_mail
      elsif (['A','R', 'S'].include?(leaveReq.status) && !isUser)
        email_id = leaveReq.user.mail
        status = "UnApproved" if leaveReq.status == 'S'
      end
      if email_id.present?
        emailNotes = l(:label_leave_email_note).to_s + " #{status} #{l(:label_by)} " + user.name
        emailNotes += "\n\n" + "#{l(:field_user)}: " + leaveReq.user_name
        emailNotes += "\n" + l(:label_leave_type).to_s + ": " + leaveReq.leave_type.subject
        emailNotes += "\n" + l(:label_start_date).to_s + ": " + leaveReq.startDate.to_s + " " + l(:label_end_date) + ": " + leaveReq.endDate.to_s
        emailNotes += "\n" + l(:label_status).to_s + ": " + status
        emailNotes += "\n" + l(:label_reason).to_s + ": " + leaveReq.leave_reasons if leaveReq.leave_reasons.present?
        err_msg = sent_emails(l(:label_leave_request_notification), user.language, email_id, emailNotes)
      end
			redirect_to action: 'index'
			flash[:notice] = l(:notice_successful_update)
      flash[:error] = err_msg if err_msg.present?
    else
      flash[:error] = leaveReq.errors.full_messages.join('<br>')
			redirect_to action: 'edit', id: params[:id]
    end
  end
	
	def set_filter_session
    if params[:searchlist] == controller_name
			session[controller_name] = Hash.new if session[controller_name].nil?
			filters = [:group_id, :user_id, :leave_type, :status]
			filters.each do |param|
				if params[param].blank? && session[controller_name].try(:[], param).present?
					session[controller_name].delete(param)
				elsif params[param].present?
					session[controller_name][param] = params[param]
				end
			end
		end
  end

end