class AttendancetypesController < ApplicationController
  prepend_before_filter :cas_require
  
  # GET /attendancetypes
  # GET /attendancetypes.json
  def index
    @attendancetypes = Attendancetype.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @attendancetypes }
    end
  end

  # GET /attendancetypes/1
  # GET /attendancetypes/1.json
  def show
    @attendancetype = Attendancetype.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @attendancetype }
    end
  end

  # GET /attendancetypes/new
  # GET /attendancetypes/new.json
  def new
    @attendancetype = Attendancetype.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @attendancetype }
    end
  end

  # GET /attendancetypes/1/edit
  def edit
    @attendancetype = Attendancetype.find(params[:id])
  end

  # POST /attendancetypes
  # POST /attendancetypes.json
  def create
    @attendancetype = Attendancetype.new(params[:attendancetype])

    respond_to do |format|
      if @attendancetype.save
        format.html { redirect_to @attendancetype, notice: 'Attendance type was successfully created.' }
        format.json { render json: @attendancetype, status: :created, location: @attendancetype }
      else
        format.html { render action: "new" }
        format.json { render json: @attendancetype.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /attendancetypes/1
  # PUT /attendancetypes/1.json
  def update
    @attendancetype = Attendancetype.find(params[:id])

    respond_to do |format|
      if @attendancetype.update_attributes(params[:attendancetype])
        format.html { redirect_to @attendancetype, notice: 'Attendance type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @attendancetype.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attendancetypes/1
  # DELETE /attendancetypes/1.json
  def destroy
    @attendancetype = Attendancetype.find(params[:id])
    @attendancetype.destroy

    respond_to do |format|
      format.html { redirect_to attendancetypes_url }
      format.json { head :no_content }
    end
  end
end
