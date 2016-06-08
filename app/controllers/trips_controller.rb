class TripsController < ApplicationController
  def index
    @trips = Trip.all
    @trips_to_display = sort_by_favorites( @trips )
    @header = "Most Popular Trips"

    if params[ :search ]
      search_array = params[:search].split(" ")
      @trips_to_display = find_all_trips( search_array ).flatten
      @header = "Your Search Results"

      if @trips_to_display.empty?
        @message = "Sorry, there are no results for that search."
        @header = "Most Popular Trips"
        @trips_to_display = sort_by_favorites( @trips )
      end
    end
  end

  def new
    @trip = Trip.new

    if !user_signed_in?
      redirect_to root_path
    end
  end

  def create
    @trip = Trip.new(trip_params)
    @trip.creator = current_user
    tags = Tag.split_tags(params[ :trip ][ :tags ])

    if @trip.save
      tags.each do |tag|
        @trip.tags << Tag.find_create_tags(tag)
      end

      if @trip.tags.length < 1
        @trip.destroy
        @errors = [ "Trip must have at least one tag.", "Please add one tag to continue." ]
        render 'new'
      else
        redirect_to new_trip_location_path( @trip )
      end
    else
      @errors = [ "Trip name cannot be blank.", "Please add a name to continue." ]
      render 'new'
    end
  end

  def show
    @trip = Trip.find_by( id: params[ :id ] )

    if @trip == nil
      redirect_to new_trip_path
    else
      @locations = @trip.locations
      @comment = Comment.new
      @creator_comments = @trip.creator_comments
      @user_comments = @trip.user_comments

      if @trip.locations.length < 3
        redirect_to new_trip_location_path( @trip )
      end
    end

  end

  def destroy
    @trip = Trip.find_by( id: params[ :id ] )
    @trip.destroy

    if request.xhr?
      render partial: "deleted_locations"
    end
  end

  private
    def trip_params
      params.require( :trip ).permit( :name )
    end
end
