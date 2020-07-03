# frozen_string_literal: true

class MetadataSamplesController < ApplicationController
  before_action :set_metadata_sample, only: [:show, :edit, :update, :destroy]

  # GET /metadata_samples
  # GET /metadata_samples.json
  def index
    @metadata_samples = MetadataSample.all
  end

  # GET /metadata_samples/1
  # GET /metadata_samples/1.json
  def show; end

  # GET /metadata_samples/new
  def new
    @metadata_sample = MetadataSample.new
  end

  # GET /metadata_samples/1/edit
  def edit; end

  # POST /metadata_samples
  # POST /metadata_samples.json
  def create
    @metadata_sample = MetadataSample.new(metadata_sample_params)
    @mss = MetadataSamplingService.field_statistics(metadata_sample, metadata_source, number_of_samples)
    respond_to do |format|
      if @metadata_sample.save
        format.html { redirect_to @metadata_sample, notice: 'Metadata sample was successfully created.' }
        format.json { render :show, status: :created, location: @metadata_sample }
      else
        format.html { render :new }
        format.json { render json: @metadata_sample.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /metadata_samples/1
  # PATCH/PUT /metadata_samples/1.json
  def update
    respond_to do |format|
      if @metadata_sample.update(metadata_sample_params)
        format.html { redirect_to @metadata_sample, notice: 'Metadata sample was successfully updated.' }
        format.json { render :show, status: :ok, location: @metadata_sample }
      else
        format.html { render :edit }
        format.json { render json: @metadata_sample.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /metadata_samples/1
  # DELETE /metadata_samples/1.json
  def destroy
    @metadata_sample.destroy
    respond_to do |format|
      format.html { redirect_to metadata_samples_url, notice: 'Metadata sample was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_metadata_sample
      @metadata_sample = MetadataSample.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def metadata_sample_params
      params.require(:metadata_sample).permit(:metadata_source, :number_of_samples, :seconds_elapsed)
    end
end
