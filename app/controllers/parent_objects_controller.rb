# frozen_string_literal: true

class ParentObjectsController < ApplicationController
  before_action :set_parent_object, only: [:show, :edit, :update, :destroy]

  # GET /parent_objects
  # GET /parent_objects.json
  def index
    @parent_objects = ParentObject.all
  end

  # GET /parent_objects/1
  # GET /parent_objects/1.json
  def show; end

  # GET /parent_objects/new
  def new
    @parent_object = ParentObject.new
  end

  # GET /parent_objects/1/edit
  def edit; end

  def mc_get(mc_url)
    metadata_cloud_username = ENV["MC_USER"]
    metadata_cloud_password = ENV["MC_PW"]
    HTTP.basic_auth(user: metadata_cloud_username, pass: metadata_cloud_password).get(mc_url)
  end

  # Takes an oid and returns the MetadataCloud Ladybird record as parsed JSON
  def fetch_ladybird_record(oid)
    mc_url = "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/#{oid}"
    fetch_record(mc_url)
  end

  # Takes a JSON record from the MetadataCloud and saves the Ladybird-specific info to the DB
  def save_ladybird_info_to_db(lb_record)
    @parent_object.update(
      bib: lb_record["orbisRecord"],
      barcode: lb_record["orbisBarcode"],
      aspace_uri: lb_record["archiveSpaceUri"],
      visibility: lb_record["itemPermission"],
      ladybird_json: lb_record,
      last_ladybird_update: DateTime.current
    )
    @parent_object.save
  end

  def fetch_voyager_record(lb_record, _oid)
    identifier_block = if lb_record["orbisBarcode"].nil?
                         "/bib/#{lb_record['orbisRecord']}"
                       else
                         "/barcode/#{lb_record['orbisBarcode']}?bib=#{lb_record['orbisRecord']}"
                       end
    mc_url = "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils#{identifier_block}"
    fetch_record(mc_url)
  end

  def save_voyager_info_to_db(v_record)
    @parent_object.update(
      holding: v_record["holdingId"],
      item: v_record["itemId"],
      voyager_json: v_record,
      last_id_update: DateTime.current,
      last_voyager_update: DateTime.current
    )
    @parent_object.save
  end

  def fetch_aspace_record(lb_record)
    identifier_block = lb_record["archiveSpaceUri"]
    mc_url = "https://metadata-api-test.library.yale.edu/metadatacloud/api/aspace#{identifier_block}"
    fetch_record(mc_url)
  end

  def fetch_record(mc_url)
    full_response = mc_get(mc_url)
    return unless full_response.status == 200
    raw_metadata = full_response.body.to_str
    JSON.parse(raw_metadata)
  end

  def save_aspace_info_to_db(v_record)
    @parent_object.update(
      aspace_json: v_record,
      last_aspace_update: DateTime.current
    )
    @parent_object.save
  end

  def get_all_mc_data(parent_object_params)
    lb_record = fetch_ladybird_record(parent_object_params[:oid])
    save_ladybird_info_to_db(lb_record)
    v_record = fetch_voyager_record(lb_record, parent_object_params[:oid])
    save_voyager_info_to_db(v_record)
    return unless lb_record["archiveSpaceUri"]
    a_record = fetch_aspace_record(lb_record)
    save_aspace_info_to_db(a_record)
  end

  # POST /parent_objects
  # POST /parent_objects.json
  def create
    @parent_object = ParentObject.new(parent_object_params)
    get_all_mc_data(parent_object_params)
    respond_to do |format|
      if @parent_object.save
        format.html { redirect_to @parent_object, notice: 'Parent object was successfully created.' }
        format.json { render :show, status: :created, location: @parent_object }

      else
        format.html { render :new }
        format.json { render json: @parent_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /parent_objects/1
  # PATCH/PUT /parent_objects/1.json
  def update
    respond_to do |format|
      if @parent_object.update(parent_object_params)
        format.html { redirect_to @parent_object, notice: 'Parent object was successfully updated.' }
        format.json { render :show, status: :ok, location: @parent_object }
      else
        format.html { render :edit }
        format.json { render json: @parent_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /parent_objects/1
  # DELETE /parent_objects/1.json
  def destroy
    @parent_object.destroy
    respond_to do |format|
      format.html { redirect_to parent_objects_url, notice: 'Parent object was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_parent_object
      @parent_object = ParentObject.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def parent_object_params
      params.require(:parent_object).permit(:oid, :bib, :holding, :item, :barcode, :aspace_uri, :last_ladybird_update, :last_voyager_update, :last_aspace_update, :visibility, :last_id_update)
    end
end
