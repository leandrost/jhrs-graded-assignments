class RecipesController < ApplicationController
  def index
    term = params[:search] || "chocolate"
    @recipes = Recipe.for(term)
  end
end
