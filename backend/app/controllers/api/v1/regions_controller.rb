module Api
  module V1
    class RegionsController < BaseController
      skip_before_action :authenticate_user!

      def index
        regions = Region.all.order(:name)
        render json: regions
      end

      def show
        region = Region.includes(:counties).find(params[:id])
        render json: region, include: :counties
      end

      def counties
        region = Region.find(params[:id])
        counties = region.counties.order(:name)
        render json: counties
      end
    end
  end
end
